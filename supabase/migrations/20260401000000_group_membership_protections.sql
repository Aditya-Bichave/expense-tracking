-- Create trigger to prevent deleting the last admin if there are other members
CREATE OR REPLACE FUNCTION public.check_last_admin_leave()
RETURNS TRIGGER AS $$
DECLARE
    admin_count INT;
    total_count INT;
BEGIN
    IF OLD.role = 'admin' THEN
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
