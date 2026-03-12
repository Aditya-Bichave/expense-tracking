-- Optimizing RLS policies (ET-56)
create or replace function public.is_group_member(group_id uuid)
returns boolean as $$
begin
  return exists (
    select 1
    from public.group_members gm
    where gm.group_id = $1
      and gm.user_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

create or replace function public.is_group_admin(group_id uuid)
returns boolean as $$
begin
  return exists (
    select 1
    from public.group_members gm
    where gm.group_id = $1
      and gm.user_id = auth.uid()
      and gm.role = 'admin'
  );
end;
$$ language plpgsql security definer;

create or replace function public.is_expense_member(expense_id uuid)
returns boolean as $$
declare
  v_group_id uuid;
begin
  select group_id into v_group_id from public.expenses where id = $1;
  if v_group_id is null then
    return false;
  end if;
  return public.is_group_member(v_group_id);
end;
$$ language plpgsql security definer;

-- Drop existing inefficient policies
drop policy if exists "Members can view groups" on public.groups;
drop policy if exists "Admins can update groups" on public.groups;
drop policy if exists "Members can view other members" on public.group_members;
drop policy if exists "Admins can add members" on public.group_members;
drop policy if exists "Admins can update members" on public.group_members;

-- Create optimized group policies
create policy "Members can view groups" on public.groups for select using (public.is_group_member(id));
create policy "Admins can update groups" on public.groups for update using (public.is_group_admin(id));
create policy "Members can view other members" on public.group_members for select using (public.is_group_member(group_id));
create policy "Admins can add members" on public.group_members for insert with check (public.is_group_admin(group_id));
create policy "Admins can update members" on public.group_members for update using (public.is_group_admin(group_id));

-- Drop existing inefficient expense policies
drop policy if exists "Members can view expenses" on public.expenses;
drop policy if exists "Members can insert expenses" on public.expenses;
drop policy if exists "Members can update expenses" on public.expenses;
drop policy if exists "Members can view payers" on public.expense_payers;
drop policy if exists "Members can insert payers" on public.expense_payers;
drop policy if exists "Members can view splits" on public.expense_splits;
drop policy if exists "Members can insert splits" on public.expense_splits;
drop policy if exists "Members can view settlements" on public.settlements;
drop policy if exists "Members can create settlements" on public.settlements;

-- Create optimized expense policies
create policy "Members can view expenses" on public.expenses for select using (public.is_group_member(group_id));
create policy "Members can insert expenses" on public.expenses for insert with check (public.is_group_member(group_id));
create policy "Members can update expenses" on public.expenses for update using (public.is_group_member(group_id));

create policy "Members can view payers" on public.expense_payers for select using (public.is_expense_member(expense_id));
create policy "Members can insert payers" on public.expense_payers for insert with check (public.is_expense_member(expense_id));

create policy "Members can view splits" on public.expense_splits for select using (public.is_expense_member(expense_id));
create policy "Members can insert splits" on public.expense_splits for insert with check (public.is_expense_member(expense_id));

create policy "Members can view settlements" on public.settlements for select using (public.is_group_member(group_id));
create policy "Members can create settlements" on public.settlements for insert with check (public.is_group_member(group_id));
