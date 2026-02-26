-- Migration: Audit Fixes (Contract Validation & Idempotency)

-- 1. Schema Updates
ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS receipt_url TEXT,
ADD COLUMN IF NOT EXISTS client_generated_id TEXT;

-- Add unique constraint for idempotency
-- Using a partial index to allow multiple nulls if client_generated_id is not provided
CREATE UNIQUE INDEX IF NOT EXISTS idx_expenses_client_generated_id
ON public.expenses(client_generated_id)
WHERE client_generated_id IS NOT NULL;

-- 2. Update create_expense_transaction RPC
CREATE OR REPLACE FUNCTION create_expense_transaction(
  p_group_id uuid,
  p_created_by uuid,
  p_amount_total numeric,
  p_currency text,
  p_description text,
  p_category_id text,
  p_expense_date timestamptz,
  p_notes text,
  p_payers jsonb,
  p_splits jsonb,
  p_receipt_url text DEFAULT NULL,
  p_client_generated_id text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_expense_id uuid;
  existing_id uuid;
  payer_record jsonb;
  split_record jsonb;
  v_total_paid numeric := 0;
  v_total_split numeric := 0;
BEGIN
  -- 0. Idempotency Check
  IF p_client_generated_id IS NOT NULL THEN
    SELECT id INTO existing_id FROM public.expenses WHERE client_generated_id = p_client_generated_id;
    IF existing_id IS NOT NULL THEN
      RETURN existing_id;
    END IF;
  END IF;

  -- 1. Validation (Anti-Tampering)
  SELECT COALESCE(SUM((p->>'amount_paid')::numeric), 0) INTO v_total_paid
  FROM jsonb_array_elements(p_payers) AS p;

  IF v_total_paid != p_amount_total THEN
    RAISE EXCEPTION 'Payer sum (%) does not match total amount (%)', v_total_paid, p_amount_total;
  END IF;

  SELECT COALESCE(SUM((s->>'computed_amount')::numeric), 0) INTO v_total_split
  FROM jsonb_array_elements(p_splits) AS s;

  IF v_total_split != p_amount_total THEN
    RAISE EXCEPTION 'Split sum (%) does not match total amount (%)', v_total_split, p_amount_total;
  END IF;

  -- Verify membership
  IF p_group_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_id = p_group_id AND user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'User is not a member of the group';
    END IF;
  END IF;

  -- 2. Insert into expenses
  INSERT INTO public.expenses (
    group_id,
    created_by,
    amount,
    currency,
    title,
    description,
    category_id,
    occurred_at,
    notes,
    receipt_url,
    client_generated_id
  )
  VALUES (
    p_group_id,
    p_created_by,
    p_amount_total,
    p_currency,
    p_description,
    p_description,
    p_category_id,
    p_expense_date,
    p_notes,
    p_receipt_url,
    p_client_generated_id
  )
  RETURNING id INTO new_expense_id;

  -- 3. Insert payers
  FOR payer_record IN SELECT * FROM jsonb_array_elements(p_payers) LOOP
    INSERT INTO public.expense_payers (expense_id, payer_user_id, amount)
    VALUES (
      new_expense_id,
      (payer_record->>'user_id')::uuid,
      (payer_record->>'amount_paid')::numeric
    );
  END LOOP;

  -- 4. Insert splits
  FOR split_record IN SELECT * FROM jsonb_array_elements(p_splits) LOOP
    INSERT INTO public.expense_splits (
      expense_id,
      user_id,
      share_type,
      share_value,
      computed_amount,
      amount
    )
    VALUES (
      new_expense_id,
      (split_record->>'user_id')::uuid,
      split_record->>'share_type',
      (split_record->>'share_value')::numeric,
      (split_record->>'computed_amount')::numeric,
      (split_record->>'computed_amount')::numeric
    );
  END LOOP;

  RETURN new_expense_id;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$;

-- 3. Update create_expense_transaction_from_json Helper
CREATE OR REPLACE FUNCTION public.create_expense_transaction_from_json(
  payload jsonb,
  creator_id uuid,
  p_client_generated_id text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  new_expense_id uuid;
  existing_id uuid;
  p_group_id uuid;
  p_title text;
  p_amount numeric;
  p_currency text;
  p_notes text;
  p_receipt_url text;
BEGIN
  -- Idempotency Check
  IF p_client_generated_id IS NOT NULL THEN
    SELECT id INTO existing_id FROM public.expenses WHERE client_generated_id = p_client_generated_id;
    IF existing_id IS NOT NULL THEN
      RETURN existing_id;
    END IF;
  END IF;

  p_group_id := (payload->>'group_id')::uuid;
  p_title := payload->>'title';
  p_amount := (payload->>'amount')::numeric;
  p_currency := payload->>'currency';
  p_notes := payload->>'notes';
  p_receipt_url := payload->>'receipt_url'; -- Extract if present

  INSERT INTO public.expenses (
    group_id,
    created_by,
    title,
    description,
    amount,
    currency,
    notes,
    occurred_at,
    receipt_url,
    client_generated_id
  )
  VALUES (
    p_group_id,
    creator_id,
    p_title,
    p_title,
    p_amount,
    p_currency,
    p_notes,
    now(),
    p_receipt_url,
    p_client_generated_id
  )
  RETURNING id INTO new_expense_id;

  RETURN new_expense_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update Recurring Processor to use Deterministic IDs
CREATE OR REPLACE FUNCTION public.process_due_recurring_rules()
RETURNS void AS $$
DECLARE
  r record;
  new_date timestamptz;
  execution_time timestamptz := now();
  deterministic_id text;
BEGIN
  FOR r IN
    SELECT * FROM public.recurring_rules
    WHERE is_active = true AND next_due_date <= execution_time
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      -- Generate Deterministic ID: rule_id + due_date (ISO string)
      deterministic_id := r.id::text || '_' || r.next_due_date::text;

      -- Execute with ID
      PERFORM public.create_expense_transaction_from_json(
        r.expense_payload,
        r.user_id,
        deterministic_id
      );

      -- Reschedule
      IF r.frequency = 'DAILY' THEN
        new_date := r.next_due_date + interval '1 day';
      ELSIF r.frequency = 'WEEKLY' THEN
        new_date := r.next_due_date + interval '1 week';
      ELSIF r.frequency = 'MONTHLY' THEN
        new_date := r.next_due_date + interval '1 month';
      ELSIF r.frequency = 'YEARLY' THEN
        new_date := r.next_due_date + interval '1 year';
      ELSE
         new_date := r.next_due_date + interval '1 day'; -- Fallback
      END IF;

      UPDATE public.recurring_rules
      SET next_due_date = new_date
      WHERE id = r.id;

    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to process recurring rule %: %', r.id, SQLERRM;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
