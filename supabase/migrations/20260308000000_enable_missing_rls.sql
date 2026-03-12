-- Enable RLS on missing tables (ET-43)
alter table if not exists public.recurring_rules enable row level security;

-- Add basic policies for recurring_rules
create policy "Users can view own recurring rules"
on public.recurring_rules for select using ( auth.uid() = user_id );

create policy "Users can insert own recurring rules"
on public.recurring_rules for insert with check ( auth.uid() = user_id );

create policy "Users can update own recurring rules"
on public.recurring_rules for update using ( auth.uid() = user_id );

create policy "Users can delete own recurring rules"
on public.recurring_rules for delete using ( auth.uid() = user_id );
