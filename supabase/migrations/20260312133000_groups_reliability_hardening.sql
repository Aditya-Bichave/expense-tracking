alter table public.group_members
  add column if not exists updated_at timestamptz default now() not null;

update public.group_members
set updated_at = coalesce(updated_at, joined_at, now())
where updated_at is null;

drop trigger if exists update_group_members_updated_at on public.group_members;
create trigger update_group_members_updated_at
  before update on public.group_members
  for each row execute procedure public.update_updated_at_column();

drop policy if exists "Admins can delete groups" on public.groups;
create policy "Admins can delete groups" on public.groups
  for delete using (
    exists (
      select 1 from public.group_members
      where group_members.group_id = groups.id
      and group_members.user_id = auth.uid()
      and group_members.role = 'admin'
    )
  );
