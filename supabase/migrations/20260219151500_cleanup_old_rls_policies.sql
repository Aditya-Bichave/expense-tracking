-- Cleanup old RLS policies that had periods in their names or used insecure logic
-- These policies were replaced by the "fix_rls_policies" migration but weren't dropped due to naming mismatches.

-- groups
DROP POLICY IF EXISTS "Members can view groups." ON groups;
DROP POLICY IF EXISTS "Admins can update groups." ON groups;

-- group_members
DROP POLICY IF EXISTS "Members can view other members." ON group_members;
DROP POLICY IF EXISTS "Admins can insert members." ON group_members; -- Note: "insert" vs "add" in new policy

-- invites
DROP POLICY IF EXISTS "Admins can view invites." ON invites;
DROP POLICY IF EXISTS "Admins can create invites." ON invites;

-- Ensure any other duplicates are removed if found (e.g. "Admins can revoke invites.")
DROP POLICY IF EXISTS "Admins can revoke invites." ON invites;
