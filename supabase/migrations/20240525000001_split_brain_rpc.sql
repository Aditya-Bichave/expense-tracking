-- Migration: Split Brain RPC and Schema Updates

-- 1. Update expenses table
ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS category_id TEXT,
ADD COLUMN IF NOT EXISTS description TEXT;

-- Migrate title to description if needed (or keep them sync)
UPDATE public.expenses SET description = title WHERE description IS NULL;

-- 2. Update expense_splits table to match new requirements
-- We need share_type (text with check), share_value, computed_amount
-- Existing: split_type (enum), amount, meta

-- Add new columns
ALTER TABLE public.expense_splits
ADD COLUMN IF NOT EXISTS share_type TEXT CHECK (share_type IN ('EQUAL', 'EXACT', 'PERCENT', 'SHARE')),
ADD COLUMN IF NOT EXISTS share_value NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS computed_amount NUMERIC(12, 2);

-- Migrate existing data (best effort)
UPDATE public.expense_splits
SET
  share_type = UPPER(split_type::text),
  computed_amount = amount,
  share_value = CASE
    WHEN split_type = 'percent' THEN 0 -- Unknown, validation might fail if re-run
    ELSE amount
  END
WHERE share_type IS NULL;

-- Make columns NOT NULL after migration (if data allows, otherwise leave nullable or handle cleanup)
-- For this task, we enforce the new schema for new rows.
-- ALTER TABLE public.expense_splits ALTER COLUMN share_type SET NOT NULL;
-- ALTER TABLE public.expense_splits ALTER COLUMN share_value SET NOT NULL;
-- ALTER TABLE public.expense_splits ALTER COLUMN computed_amount SET NOT NULL;

-- 3. Create RPC function
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
  p_splits jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_expense_id uuid;
  payer_record jsonb;
  split_record jsonb;
  v_total_paid numeric := 0;
  v_total_split numeric := 0;
BEGIN
  -- 1. Validation (Anti-Tampering)
  -- Sum of payers must equal total
  SELECT COALESCE(SUM((p->>'amount_paid')::numeric), 0) INTO v_total_paid
  FROM jsonb_array_elements(p_payers) AS p;

  IF v_total_paid != p_amount_total THEN
    RAISE EXCEPTION 'Payer sum (%) does not match total amount (%)', v_total_paid, p_amount_total;
  END IF;

  -- Sum of splits (computed_amount) must equal total
  SELECT COALESCE(SUM((s->>'computed_amount')::numeric), 0) INTO v_total_split
  FROM jsonb_array_elements(p_splits) AS s;

  IF v_total_split != p_amount_total THEN
    RAISE EXCEPTION 'Split sum (%) does not match total amount (%)', v_total_split, p_amount_total;
  END IF;

  -- Verify membership (RLS usually handles this, but explicitly checked here if needed)
  IF p_group_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_id = p_group_id AND user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'User is not a member of the group';
    END IF;
  END IF;

  -- Validate created_by matches auth.uid() (optional, but good practice)
  IF p_created_by != auth.uid() THEN
    RAISE EXCEPTION 'User ID mismatch';
  END IF;

  -- 2. Insert into expenses
  INSERT INTO public.expenses (
    group_id,
    created_by,
    amount, -- Map p_amount_total to existing 'amount' column
    currency,
    title, -- Map p_description to existing 'title' column
    description, -- Also store in new column
    category_id,
    occurred_at, -- Map p_expense_date to 'occurred_at'
    notes
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
    p_notes
  )
  RETURNING id INTO new_expense_id;

  -- 3. Insert payers
  FOR payer_record IN SELECT * FROM jsonb_array_elements(p_payers) LOOP
    INSERT INTO public.expense_payers (expense_id, payer_user_id, amount) -- Map payer_user_id, amount
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
      amount -- Map computed_amount to legacy 'amount' for compatibility
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
