-- Create group_goals and contributions

CREATE TYPE goal_status AS ENUM ('active', 'achieved', 'archived');

CREATE TABLE group_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    name TEXT NOT NULL,
    target_amount NUMERIC(15, 2) NOT NULL,
    current_amount NUMERIC(15, 2) DEFAULT 0,
    deadline DATE,
    status goal_status DEFAULT 'active',
    icon TEXT,
    color TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE group_goal_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES group_goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    amount NUMERIC(15, 2) NOT NULL,
    note TEXT,
    contributed_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE group_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_goal_contributions ENABLE ROW LEVEL SECURITY;

-- group_goals policies
CREATE POLICY "Members can view group goals" ON group_goals FOR SELECT
USING ( is_member_of(group_id) );

CREATE POLICY "Members can manage group goals" ON group_goals FOR ALL
USING ( is_member_of(group_id) )
WITH CHECK ( is_member_of(group_id) );

-- group_goal_contributions policies
CREATE POLICY "Members can view contributions" ON group_goal_contributions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_goals gg
    WHERE gg.id = group_goal_contributions.goal_id
    AND is_member_of(gg.group_id)
  )
);

CREATE POLICY "Members can insert contributions" ON group_goal_contributions FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_goals gg
    WHERE gg.id = group_goal_contributions.goal_id
    AND is_member_of(gg.group_id)
  )
);

CREATE POLICY "Members can delete contributions" ON group_goal_contributions FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM group_goals gg
    WHERE gg.id = group_goal_contributions.goal_id
    AND is_member_of(gg.group_id)
  )
  AND user_id = auth.uid() -- Only delete own contributions? Or admin? Let's say own for now.
);


-- Trigger to update current_amount
CREATE OR REPLACE FUNCTION update_group_goal_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE group_goals SET current_amount = current_amount + NEW.amount, updated_at = NOW() WHERE id = NEW.goal_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE group_goals SET current_amount = current_amount - OLD.amount, updated_at = NOW() WHERE id = OLD.goal_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE group_goals SET current_amount = current_amount - OLD.amount + NEW.amount, updated_at = NOW() WHERE id = NEW.goal_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_goal_amount_trigger
AFTER INSERT OR UPDATE OR DELETE ON group_goal_contributions
FOR EACH ROW EXECUTE PROCEDURE update_group_goal_amount();

-- Trigger for updated_at on group_goals
CREATE TRIGGER update_group_goals_updated_at
BEFORE UPDATE ON group_goals
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
