-- PROFILES
create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = user_id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = user_id );

create policy "Users can select own profile."
  on profiles for select
  using ( auth.uid() = user_id );

-- GROUPS
create policy "Members can view groups."
  on groups for select
  using (
    auth.uid() in (
      select user_id from group_members where group_id = id
    )
  );

create policy "Users can create groups."
  on groups for insert
  with check ( auth.uid() = created_by );

create policy "Admins can update groups."
  on groups for update
  using (
    auth.uid() in (
      select user_id from group_members where group_id = id and role = 'admin'
    )
  );

-- GROUP_MEMBERS
create policy "Members can view other members."
  on group_members for select
  using (
    auth.uid() in (
      select user_id from group_members where group_id = group_members.group_id
    )
  );

create policy "Admins can insert members."
  on group_members for insert
  with check (
    auth.uid() in (
      select user_id from group_members where group_id = group_id and role = 'admin'
    )
  );

create policy "Users can leave group (delete own membership)."
  on group_members for delete
  using ( auth.uid() = user_id );

-- INVITES
create policy "Admins can create invites."
  on invites for insert
  with check (
    auth.uid() in (
      select user_id from group_members where group_id = group_id and role = 'admin'
    )
  );

create policy "Admins can view invites."
  on invites for select
  using (
    auth.uid() in (
      select user_id from group_members where group_id = group_id and role = 'admin'
    )
  );

-- EXPENSES (and related tables)
-- Policy helper function to check membership
create or replace function is_member_of(_group_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from group_members
    where group_id = _group_id
    and user_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- Expenses
create policy "Members can view expenses."
  on expenses for select
  using ( is_member_of(group_id) );

create policy "Members can insert expenses."
  on expenses for insert
  with check ( is_member_of(group_id) );

create policy "Members can update expenses."
  on expenses for update
  using ( is_member_of(group_id) );

-- Expense Payers
create policy "Members can view expense payers."
  on expense_payers for select
  using (
    exists (
      select 1 from expenses
      where id = expense_id
      and is_member_of(group_id)
    )
  );

create policy "Members can insert expense payers."
  on expense_payers for insert
  with check (
    exists (
      select 1 from expenses
      where id = expense_id
      and is_member_of(group_id)
    )
  );

-- Expense Splits
create policy "Members can view expense splits."
  on expense_splits for select
  using (
    exists (
      select 1 from expenses
      where id = expense_id
      and is_member_of(group_id)
    )
  );

create policy "Members can insert expense splits."
  on expense_splits for insert
  with check (
    exists (
      select 1 from expenses
      where id = expense_id
      and is_member_of(group_id)
    )
  );

-- Settlements
create policy "Members can view settlements."
  on settlements for select
  using ( is_member_of(group_id) );

create policy "Members can insert settlements."
  on settlements for insert
  with check ( is_member_of(group_id) );
