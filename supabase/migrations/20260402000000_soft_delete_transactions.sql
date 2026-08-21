-- Add deleted_at column and indexes to expenses and incomes tables for soft delete support

ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_expenses_deleted_at ON public.expenses (deleted_at) WHERE deleted_at IS NULL;

ALTER TABLE public.incomes ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_incomes_deleted_at ON public.incomes (deleted_at) WHERE deleted_at IS NULL;

-- Ensure users can select and update their soft-deleted transactions
-- (The existing user_id / auth.uid() owner policies allow update/select on owned rows regardless of deleted_at)
