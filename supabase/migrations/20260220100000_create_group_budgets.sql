-- Create group_budgets table

CREATE TYPE budget_period AS ENUM ('daily', 'weekly', 'monthly', 'yearly');

CREATE TABLE group_budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    category_id UUID NOT NULL, -- Assuming linked to global or group categories (for now just UUID)
    amount NUMERIC(15, 2) NOT NULL,
    period budget_period NOT NULL DEFAULT 'monthly',
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE group_budgets ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Members can view group budgets" ON group_budgets FOR SELECT
USING ( is_member_of(group_id) );

CREATE POLICY "Admins can manage group budgets" ON group_budgets FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_budgets.group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
);

-- Trigger for updated_at
CREATE TRIGGER update_group_budgets_updated_at
BEFORE UPDATE ON group_budgets
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
