-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create ENUM types
create type group_role as enum ('admin', 'member', 'viewer');
create type split_type as enum ('equal', 'percent', 'exact');

-- PROFILES
create table public.profiles (
  user_id uuid references auth.users not null primary key,
  phone text,
  display_name text,
  created_at timestamptz default now()
);

-- GROUPS
create table public.groups (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_by uuid references auth.users not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- GROUP MEMBERS
create table public.group_members (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid references public.groups on delete cascade not null,
  user_id uuid references auth.users not null,
  role group_role default 'member'::group_role,
  joined_at timestamptz default now(),
  unique(group_id, user_id)
);

-- INVITES
create table public.invites (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid references public.groups on delete cascade not null,
  created_by uuid references auth.users not null,
  token text unique not null,
  expires_at timestamptz,
  max_uses int default 1,
  uses_count int default 0,
  created_at timestamptz default now()
);

-- EXPENSES (Group-scoped)
create table public.expenses (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid references public.groups on delete cascade not null,
  created_by uuid references auth.users not null,
  title text not null,
  amount numeric not null,
  currency text default 'USD',
  occurred_at timestamptz default now(),
  notes text,
  updated_at timestamptz default now(),
  created_at timestamptz default now()
);

-- EXPENSE PAYERS
create table public.expense_payers (
  id uuid primary key default uuid_generate_v4(),
  expense_id uuid references public.expenses on delete cascade not null,
  payer_user_id uuid references auth.users not null,
  amount numeric not null
);

-- EXPENSE SPLITS
create table public.expense_splits (
  id uuid primary key default uuid_generate_v4(),
  expense_id uuid references public.expenses on delete cascade not null,
  user_id uuid references auth.users not null,
  amount numeric not null,
  split_type split_type default 'equal'::split_type,
  meta jsonb
);

-- SETTLEMENTS
create table public.settlements (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid references public.groups on delete cascade not null,
  from_user_id uuid references auth.users not null,
  to_user_id uuid references auth.users not null,
  amount numeric not null,
  currency text default 'USD',
  created_at timestamptz default now()
);

-- Indexes
create index idx_groups_created_by on public.groups(created_by);
create index idx_group_members_group_id on public.group_members(group_id);
create index idx_group_members_user_id on public.group_members(user_id);
create index idx_invites_token on public.invites(token);
create index idx_expenses_group_id on public.expenses(group_id);
create index idx_settlements_group_id on public.settlements(group_id);

-- Updated_at trigger function
create or replace function update_updated_at_column()
returns trigger as $$
begin
   new.updated_at = now();
   return new;
end;
$$ language 'plpgsql';

create trigger update_groups_updated_at before update
on public.groups for each row execute procedure update_updated_at_column();

create trigger update_expenses_updated_at before update
on public.expenses for each row execute procedure update_updated_at_column();

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.invites enable row level security;
alter table public.expenses enable row level security;
alter table public.expense_payers enable row level security;
alter table public.expense_splits enable row level security;
alter table public.settlements enable row level security;
