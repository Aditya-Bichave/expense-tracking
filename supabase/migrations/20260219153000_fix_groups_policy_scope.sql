-- Fix scope resolution bug in 'groups' policies
-- Previous migration used 'id' which resolved to group_members.id instead of groups.id

DROP POLICY IF EXISTS "Members can view groups" ON groups;
CREATE POLICY "Members can view groups" ON groups FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Admins can update groups" ON groups;
CREATE POLICY "Admins can update groups" ON groups FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
    AND gm.role = 'admin'
  )
);
