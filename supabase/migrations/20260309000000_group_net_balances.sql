-- View: Calculates exactly how much a user is up/down in a specific group
-- Uses security_invoker = true so that RLS is applied when querying this view
CREATE OR REPLACE VIEW public.group_net_balances WITH (security_invoker = true) AS
WITH expense_paid AS (
    -- How much each user PAID for expenses
    SELECT e.group_id, ep.payer_user_id AS user_id, SUM(ep.amount) AS total_paid
    FROM public.expense_payers ep
    JOIN public.expenses e ON ep.expense_id = e.id
    WHERE e.group_id IS NOT NULL
    GROUP BY e.group_id, ep.payer_user_id
),
expense_owed AS (
    -- How much each user OWES for expenses
    SELECT e.group_id, es.user_id, SUM(es.amount) AS total_owed
    FROM public.expense_splits es
    JOIN public.expenses e ON es.expense_id = e.id
    WHERE e.group_id IS NOT NULL
    GROUP BY e.group_id, es.user_id
),
settlements_sent AS (
    -- How much user has SENT in manual settlements (from_user_id)
    SELECT group_id, from_user_id AS user_id, SUM(amount) AS total_sent
    FROM public.settlements
    GROUP BY group_id, from_user_id
),
settlements_received AS (
    -- How much user has RECEIVED in manual settlements (to_user_id)
    SELECT group_id, to_user_id AS user_id, SUM(amount) AS total_received
    FROM public.settlements
    GROUP BY group_id, to_user_id
),
all_group_users AS (
    -- Get all users in the group to ensure we don't miss anyone
    SELECT group_id, user_id FROM public.group_members
)
SELECT
    agu.group_id,
    agu.user_id,
    p.full_name AS user_name,
    p.upi_id AS to_user_upi,
    -- Formula: Total Paid - Total Owed + Total Settlements Sent - Total Settlements Received
    -- Cast to NUMERIC(15, 2) to match DB types and maintain accuracy
    CAST(
        COALESCE(ep.total_paid, 0) - COALESCE(eo.total_owed, 0) + COALESCE(ss.total_sent, 0) - COALESCE(sr.total_received, 0)
        AS NUMERIC(15, 2)
    ) AS net_balance
FROM all_group_users agu
JOIN public.profiles p ON agu.user_id = p.id
LEFT JOIN expense_paid ep ON agu.group_id = ep.group_id AND agu.user_id = ep.user_id
LEFT JOIN expense_owed eo ON agu.group_id = eo.group_id AND agu.user_id = eo.user_id
LEFT JOIN settlements_sent ss ON agu.group_id = ss.group_id AND agu.user_id = ss.user_id
LEFT JOIN settlements_received sr ON agu.group_id = sr.group_id AND agu.user_id = sr.user_id;
