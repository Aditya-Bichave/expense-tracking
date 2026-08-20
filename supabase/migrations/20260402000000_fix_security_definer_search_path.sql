-- Migration to fix function_search_path_mutable security issue for all SECURITY DEFINER functions.
-- Sets explicit search_path = public, pg_temp on all 14 SECURITY DEFINER functions across migrations.

-- 1. From 20240523000000_foundation_pack.sql / 20240524000000_viral_loop.sql: public.handle_new_user()
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, phone, email, display_name)
  VALUES (
    new.id,
    new.phone,
    new.email,
    COALESCE(new.raw_user_meta_data->>'display_name', 'Guest')
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN new;
END;
$$;

-- 2. From 20240524000000_viral_loop.sql: public.increment_invite_uses(invite_id UUID)
CREATE OR REPLACE FUNCTION public.increment_invite_uses(invite_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.group_invites
    SET uses_count = uses_count + 1,
        updated_at = NOW()
    WHERE id = invite_id;
END;
$$;

-- 3. From 20240524000001_phase_2a_groups.sql: public.handle_new_group()
CREATE OR REPLACE FUNCTION public.handle_new_group()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (new.id, new.created_by, 'admin');
  RETURN new;
END;
$$;

-- 4. From 20240525000001_split_brain_rpc.sql / 20260225100000_audit_fixes.sql: public.create_expense_transaction
CREATE OR REPLACE FUNCTION public.create_expense_transaction(
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
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_expense_id uuid;
  existing_id uuid;
  payer_record jsonb;
  split_record jsonb;
  v_total_paid numeric := 0;
  v_total_split numeric := 0;
BEGIN
  -- Idempotency Check
  IF p_client_generated_id IS NOT NULL THEN
    SELECT id INTO existing_id FROM public.expenses WHERE client_generated_id = p_client_generated_id;
    IF existing_id IS NOT NULL THEN
      RETURN existing_id;
    END IF;
  END IF;

  -- 1. Validation (Anti-Tampering)
  IF p_amount_total <= 0 THEN
    RAISE EXCEPTION 'Total amount must be greater than zero.';
  END IF;

  FOR payer_record IN SELECT * FROM jsonb_array_elements(p_payers)
  LOOP
    v_total_paid := v_total_paid + (payer_record->>'amount')::numeric;
  END LOOP;

  IF v_total_paid <> p_amount_total THEN
    RAISE EXCEPTION 'Sum of payers (%) does not match total amount (%).', v_total_paid, p_amount_total;
  END IF;

  FOR split_record IN SELECT * FROM jsonb_array_elements(p_splits)
  LOOP
    v_total_split := v_total_split + (split_record->>'amount')::numeric;
  END LOOP;

  IF v_total_split <> p_amount_total THEN
    RAISE EXCEPTION 'Sum of splits (%) does not match total amount (%).', v_total_split, p_amount_total;
  END IF;

  -- 2. Insert Main Expense Record
  INSERT INTO public.expenses (
    group_id,
    created_by,
    title,
    amount,
    currency,
    notes,
    occurred_at,
    category_id,
    client_generated_id
  ) VALUES (
    p_group_id,
    p_created_by,
    p_description,
    p_amount_total,
    p_currency,
    p_notes,
    p_expense_date,
    NULLIF(p_category_id, '')::uuid,
    p_client_generated_id
  )
  RETURNING id INTO new_expense_id;

  -- 3. Insert Payers
  FOR payer_record IN SELECT * FROM jsonb_array_elements(p_payers)
  LOOP
    INSERT INTO public.expense_payers (
      expense_id,
      payer_user_id,
      amount
    ) VALUES (
      new_expense_id,
      (payer_record->>'payer_user_id')::uuid,
      (payer_record->>'amount')::numeric
    );
  END LOOP;

  -- 4. Insert Splits
  FOR split_record IN SELECT * FROM jsonb_array_elements(p_splits)
  LOOP
    INSERT INTO public.expense_splits (
      expense_id,
      user_id,
      amount,
      split_type
    ) VALUES (
      new_expense_id,
      (split_record->>'user_id')::uuid,
      (split_record->>'amount')::numeric,
      (split_record->>'split_type')::split_type
    );
  END LOOP;

  RETURN new_expense_id;
END;
$$;

-- 5. From 20260218140000_phase_3c_automation.sql: public.trigger_set_audit_fields()
CREATE OR REPLACE FUNCTION public.trigger_set_audit_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF new.created_by IS NULL THEN
       new.created_by := auth.uid();
    END IF;
    IF new.updated_by IS NULL THEN
       new.updated_by := new.created_by;
    END IF;
  ELSIF (TG_OP = 'UPDATE') THEN
    new.created_by := old.created_by;
    new.created_at := old.created_at;
    new.updated_by := auth.uid();
    new.updated_at := now();
  END IF;
  RETURN new;
END;
$$;

-- 6. From 20260218140000_phase_3c_automation.sql / 20260225100000_audit_fixes.sql: public.create_expense_transaction_from_json
CREATE OR REPLACE FUNCTION public.create_expense_transaction_from_json(
  payload jsonb,
  creator_id uuid,
  p_client_generated_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
  p_receipt_url := payload->>'receipt_url';

  INSERT INTO public.expenses (
    group_id,
    created_by,
    title,
    amount,
    currency,
    notes,
    occurred_at,
    client_generated_id
  ) VALUES (
    p_group_id,
    creator_id,
    p_title,
    p_amount,
    p_currency,
    p_notes,
    now(),
    p_client_generated_id
  )
  RETURNING id INTO new_expense_id;

  RETURN new_expense_id;
END;
$$;

-- 7. From 20260218140000_phase_3c_automation.sql / 20260225100000_audit_fixes.sql: public.process_due_recurring_rules()
CREATE OR REPLACE FUNCTION public.process_due_recurring_rules()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

-- 8. From 20260401000000_group_membership_protections.sql: public.check_last_admin_leave()
CREATE OR REPLACE FUNCTION public.check_last_admin_leave()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    admin_count INT;
    total_count INT;
BEGIN
    IF OLD.role = 'admin' THEN
        -- Acquire a row-level lock on the parent group to serialize concurrent deletes
        PERFORM 1 FROM public.groups WHERE id = OLD.group_id FOR UPDATE;

        SELECT COUNT(*) INTO admin_count FROM public.group_members WHERE group_id = OLD.group_id AND role = 'admin';
        SELECT COUNT(*) INTO total_count FROM public.group_members WHERE group_id = OLD.group_id;

        IF admin_count <= 1 AND total_count > 1 THEN
            RAISE EXCEPTION 'Cannot remove the last admin when other members exist. Transfer ownership first.';
        END IF;
    END IF;
    RETURN OLD;
END;
$$;

-- 9. From 20260401000000_group_membership_protections.sql: public.check_net_balance_before_leave()
CREATE OR REPLACE FUNCTION public.check_net_balance_before_leave()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    user_balance NUMERIC(15,2);
BEGIN
    -- Acquire a row-level lock on the parent group to serialize concurrent deletes/transactions
    PERFORM 1 FROM public.groups WHERE id = OLD.group_id FOR UPDATE;

    SELECT net_balance INTO user_balance
    FROM public.group_net_balances
    WHERE group_id = OLD.group_id AND user_id = OLD.user_id;

    IF user_balance IS NOT NULL AND (user_balance > 0.01 OR user_balance < -0.01) THEN
        RAISE EXCEPTION 'Cannot remove member with unsettled balances. Please settle all debts first.';
    END IF;

    RETURN OLD;
END;
$$;

-- 10. From 20260401000000_group_membership_protections.sql: public.update_expense_with_relations
CREATE OR REPLACE FUNCTION public.update_expense_with_relations(
  p_expense_id UUID,
  p_expense_data JSONB,
  p_payers JSONB,
  p_splits JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Update the expense record
  UPDATE public.expenses
  SET
    title = p_expense_data->>'title',
    amount = (p_expense_data->>'amount')::NUMERIC(15, 2),
    currency = p_expense_data->>'currency',
    notes = p_expense_data->>'notes',
    occurred_at = (p_expense_data->>'occurred_at')::TIMESTAMPTZ,
    category_id = (p_expense_data->>'category_id')::UUID,
    updated_at = NOW()
  WHERE id = p_expense_id;

  -- Delete existing relations
  DELETE FROM public.expense_payers WHERE expense_id = p_expense_id;
  DELETE FROM public.expense_splits WHERE expense_id = p_expense_id;

  -- Insert new payers (if any)
  IF jsonb_array_length(p_payers) > 0 THEN
    INSERT INTO public.expense_payers (expense_id, payer_user_id, amount)
    SELECT
      p_expense_id,
      (payer->>'payer_user_id')::UUID,
      (payer->>'amount')::NUMERIC(15, 2)
    FROM jsonb_array_elements(p_payers) AS payer;
  END IF;

  -- Insert new splits (if any)
  IF jsonb_array_length(p_splits) > 0 THEN
    INSERT INTO public.expense_splits (expense_id, user_id, amount, split_type)
    SELECT
      p_expense_id,
      (split->>'user_id')::UUID,
      (split->>'amount')::NUMERIC(15, 2),
      (split->>'split_type')::split_type
    FROM jsonb_array_elements(p_splits) AS split;
  END IF;

END;
$$;
