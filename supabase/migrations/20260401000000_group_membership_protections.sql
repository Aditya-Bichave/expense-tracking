-- Create trigger to prevent deleting the last admin if there are other members
CREATE OR REPLACE FUNCTION public.check_last_admin_leave()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS ensure_admin_before_leave ON public.group_members;
CREATE TRIGGER ensure_admin_before_leave
    BEFORE DELETE ON public.group_members
    FOR EACH ROW
    EXECUTE PROCEDURE public.check_last_admin_leave();

-- Create trigger to prevent members with non-zero balances from leaving or being kicked
CREATE OR REPLACE FUNCTION public.check_net_balance_before_leave()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS ensure_settled_before_leave ON public.group_members;
CREATE TRIGGER ensure_settled_before_leave
    BEFORE DELETE ON public.group_members
    FOR EACH ROW
    EXECUTE PROCEDURE public.check_net_balance_before_leave();

-- Function to atomically update an expense and its relations (payers, splits)
CREATE OR REPLACE FUNCTION public.update_expense_with_relations(
  p_expense_id UUID,
  p_expense_data JSONB,
  p_payers JSONB,
  p_splits JSONB
)
RETURNS VOID AS $$
BEGIN
  -- Update the expense record (ignoring 'id' and 'created_at' inside the JSON if passed)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
