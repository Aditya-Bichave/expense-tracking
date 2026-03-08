-- 1. DEVICE TOKENS TABLE
create table public.user_fcm_tokens (
  user_id uuid references public.profiles(id) on delete cascade not null,
  device_id text not null, -- Unique identifier for the phone/browser
  fcm_token text not null,
  platform text not null check (platform in ('ios', 'android', 'web')),
  updated_at timestamptz default now() not null,
  primary key (user_id, device_id)
);

-- RLS: Users can only manage their own tokens
alter table public.user_fcm_tokens enable row level security;

create policy "Users can view their own tokens" on public.user_fcm_tokens
  for select using (auth.uid() = user_id);

create policy "Users can insert their own tokens" on public.user_fcm_tokens
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own tokens" on public.user_fcm_tokens
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can delete their own tokens" on public.user_fcm_tokens
  for delete using (auth.uid() = user_id);

-- 2. RATE LIMITING & AUDIT LOG TABLE
create table public.nudge_logs (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  from_user_id uuid references public.profiles(id) on delete cascade not null,
  to_user_id uuid references public.profiles(id) on delete cascade not null,
  amount_owed numeric not null,
  currency text not null,
  created_at timestamptz default now() not null
);

-- Index for blazing fast rate-limit lookups
create index idx_nudge_lookup on public.nudge_logs(from_user_id, to_user_id, group_id, created_at desc);

-- RLS: Service role only (Edge Function writes to this, users cannot spoof logs)
alter table public.nudge_logs enable row level security;
-- No policies created means only postgres/service_role can insert/select.
