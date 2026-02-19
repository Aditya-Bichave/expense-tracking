CREATE POLICY "Users can create groups" ON groups FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Members can view groups" ON groups FOR SELECT USING (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid()));
CREATE POLICY "Admins can update groups" ON groups FOR UPDATE USING (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid() AND gm.role = 'admin'));
CREATE POLICY "Members can view other members" ON group_members FOR SELECT USING (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_members.group_id AND gm.user_id = auth.uid()));
CREATE POLICY "Admins can add members" ON group_members FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_members.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin'));
CREATE POLICY "Admins can update members" ON group_members FOR UPDATE USING (EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_members.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin'));
CREATE POLICY "Members can leave" ON group_members FOR DELETE USING (auth.uid() = user_id);
