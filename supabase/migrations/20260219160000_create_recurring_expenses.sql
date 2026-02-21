-- Create recurring_expenses table

CREATE TYPE recurring_frequency AS ENUM ('daily', 'weekly', 'monthly', 'yearly');

CREATE TABLE recurring_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    title TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    frequency recurring_frequency NOT NULL,
    interval INT DEFAULT 1,
    start_date DATE NOT NULL,
    next_run_at TIMESTAMPTZ NOT NULL,
    last_run_at TIMESTAMPTZ,
    notes TEXT,
    split_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE recurring_expenses ENABLE ROW LEVEL SECURITY;

-- Policies (using the secure is_member_of function)
CREATE POLICY "Members can view recurring expenses" ON recurring_expenses FOR SELECT
USING ( is_member_of(group_id) );

CREATE POLICY "Members can insert recurring expenses" ON recurring_expenses FOR INSERT
WITH CHECK ( is_member_of(group_id) );

CREATE POLICY "Members can update recurring expenses" ON recurring_expenses FOR UPDATE
USING ( is_member_of(group_id) );

CREATE POLICY "Members can delete recurring expenses" ON recurring_expenses FOR DELETE
USING ( is_member_of(group_id) );

-- Trigger
CREATE TRIGGER update_recurring_expenses_updated_at
BEFORE UPDATE ON recurring_expenses
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Index for cron job performance
CREATE INDEX idx_recurring_expenses_next_run ON recurring_expenses(next_run_at) WHERE is_active = true;
