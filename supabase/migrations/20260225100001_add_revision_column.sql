-- Migration: Add monotonic revision column to expenses table

-- 1. Add revision column
ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS revision INTEGER DEFAULT 1 NOT NULL;

-- 2. Add function and trigger to auto-increment revision on UPDATE
CREATE OR REPLACE FUNCTION increment_revision()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    -- Only increment if revision is not explicitly provided in the UPDATE statement or if it's the same
    -- Wait, optimistic concurrency requires the client to send the *current* revision.
    -- If the client sends `revision = X`, and current DB is `Y`, and `X != Y`, we should reject.
    -- But since we are mostly doing upserts from client, we can enforce it here.
    IF NEW.revision IS NOT NULL AND OLD.revision IS NOT NULL THEN
      IF NEW.revision != OLD.revision THEN
        -- Client provided a different revision than expected (they didn't match the current)
        -- Actually, optimistic concurrency is usually handled in the query: UPDATE ... WHERE id = ID AND revision = EXPECTED_REVISION
        -- So if 0 rows are updated, it's a conflict. We just need to increment it.
        NEW.revision = OLD.revision + 1;
      ELSE
        NEW.revision = OLD.revision + 1;
      END IF;
    ELSE
      NEW.revision = COALESCE(OLD.revision, 0) + 1;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_expenses_revision ON public.expenses;
CREATE TRIGGER trg_expenses_revision
BEFORE UPDATE ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION increment_revision();

-- 3. Update create_expense_transaction to handle existing expense update properly if we want idempotency to return it
-- The existing RPC handles idempotency by checking `client_generated_id` and returning `existing_id`. It doesn't update.
-- Let's ensure our UI sends expected revision during updates.
