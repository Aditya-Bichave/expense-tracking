-- Migration to add missing indexes on foreign keys and columns used in WHERE/JOIN clauses
-- Created for performance optimization

CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_account_id ON expenses(account_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user_id ON expense_splits(user_id);
CREATE INDEX IF NOT EXISTS idx_expense_payers_expense_id ON expense_payers(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_payers_user_id ON expense_payers(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_user_id ON recurring_rules(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_category_id ON recurring_rules(category_id);
