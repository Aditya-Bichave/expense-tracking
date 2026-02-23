-- Alter groups table
alter table public.groups
  add column if not exists type text check (type in ('trip', 'couple', 'home', 'custom')),
  add column if not exists currency text default 'USD' not null,
  add column if not exists photo_url text,
  add column if not exists is_archived boolean default false not null;

-- Set default type for existing rows (if any)
update public.groups set type = 'custom' where type is null;
alter table public.groups alter column type set not null;

-- Drop existing policies to recreate them
drop policy if exists "Users can view joined groups" on public.groups;
drop policy if exists "Users can create groups" on public.groups;
drop policy if exists "Admins can update groups" on public.groups;
drop policy if exists "Users can view members of their groups" on public.group_members;

-- Policies for groups
create policy "Users can view joined groups" on public.groups
  for select using (
    exists (
      select 1 from public.group_members
      where group_members.group_id = groups.id
      and group_members.user_id = auth.uid()
    )
  );

create policy "Users can create groups" on public.groups
  for insert with check (auth.uid() = created_by);

create policy "Admins can update groups" on public.groups
  for update using (
    exists (
      select 1 from public.group_members
      where group_members.group_id = groups.id
      and group_members.user_id = auth.uid()
      and group_members.role = 'admin'
    )
  );

-- Policies for group_members
create policy "Users can view members of their groups" on public.group_members
  for select using (
    exists (
      select 1 from public.group_members as gm
      where gm.group_id = group_members.group_id
      and gm.user_id = auth.uid()
    )
  );

-- Auto-membership trigger
create or replace function public.handle_new_group()
returns trigger as $$
begin
  insert into public.group_members (group_id, user_id, role)
  values (new.id, new.created_by, 'admin');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_group_created on public.groups;
create trigger on_group_created
  after insert on public.groups
  for each row execute procedure public.handle_new_group();
