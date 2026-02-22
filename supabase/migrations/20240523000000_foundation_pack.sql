-- 1. Create Profiles Table
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  full_name text,
  email text unique,
  phone text unique,
  avatar_url text,
  currency text default 'INR',
  timezone text default 'Asia/Kolkata',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Create Storage Bucket (Avatars)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 3. Enable RLS on Profiles
alter table public.profiles enable row level security;

-- 4. Create RLS Policies

-- Policy 1: Users can read their own profile
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
on public.profiles for select using ( auth.uid() = id );

-- Policy 2: Users can update their own profile
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update using ( auth.uid() = id );

-- Policy 3: Users can upload avatars
drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
on storage.objects for insert with check (
  bucket_id = 'avatars' and auth.uid() = owner
);

-- Policy 4: Users can view avatars
drop policy if exists "Anyone can view avatars" on storage.objects;
create policy "Anyone can view avatars"
on storage.objects for select using ( bucket_id = 'avatars' );

-- 5. Auto-create Profile on Signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, phone, email)
  values (new.id, new.phone, new.email);
  return new;
end;
$$ language plpgsql security definer;

-- Trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
