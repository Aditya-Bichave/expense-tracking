-- Fix RLS Policies for Group Isolation to prevent cross-group data leakage

-- 1. groups: Ensure strict correlation between group and user membership
DROP POLICY IF EXISTS "Members can view groups" ON groups;
CREATE POLICY "Members can view groups" ON groups FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = id
    AND gm.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Admins can update groups" ON groups;
CREATE POLICY "Admins can update groups" ON groups FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
);

-- 2. group_members: Critical fix. Users should only see members of groups they are ALSO in.
DROP POLICY IF EXISTS "Members can view other members" ON group_members;
CREATE POLICY "Members can view other members" ON group_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members my_gm
    WHERE my_gm.group_id = group_members.group_id
    AND my_gm.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Admins can update members" ON group_members;
CREATE POLICY "Admins can update members" ON group_members FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM group_members my_gm
    WHERE my_gm.group_id = group_members.group_id
    AND my_gm.user_id = auth.uid()
    AND my_gm.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can add members" ON group_members;
CREATE POLICY "Admins can add members" ON group_members FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members my_gm
    WHERE my_gm.group_id = group_id
    AND my_gm.user_id = auth.uid()
    AND my_gm.role = 'admin'
  )
);

-- 3. invites: Ensure only admins of the specific group can see/manage invites
DROP POLICY IF EXISTS "Admins can view invites" ON invites;
CREATE POLICY "Admins can view invites" ON invites FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = invites.group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can create invites" ON invites;
CREATE POLICY "Admins can create invites" ON invites FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = invites.group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can revoke invites" ON invites;
CREATE POLICY "Admins can revoke invites" ON invites FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = invites.group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
);
