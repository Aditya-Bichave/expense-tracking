CREATE POLICY "Admins can create invites" ON invites FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = invites.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin'));
CREATE POLICY "Members can view invites" ON invites FOR SELECT USING (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = invites.group_id AND gm.user_id = auth.uid()));
CREATE POLICY "Admins can revoke invites" ON invites FOR DELETE USING (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = invites.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin'));
