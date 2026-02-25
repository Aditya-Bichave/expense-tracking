-- Enable pg_cron if not enabled
create extension if not exists pg_cron with schema extensions;

-- Add UPI ID to profiles
alter table public.profiles add column if not exists upi_id text;

-- Add Audit columns to expenses
-- created_at and updated_at already exist
alter table public.expenses
add column if not exists created_by uuid references auth.users(id),
add column if not exists updated_by uuid references auth.users(id);

-- Recurring Rules Table
create table if not exists public.recurring_rules (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  group_id uuid references public.groups(id),
  expense_payload jsonb not null,
  frequency text not null check (frequency in ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY')),
  timezone text not null default 'Asia/Kolkata',
  next_due_date timestamptz not null,
  is_active boolean default true,
  created_at timestamptz default now()
);

create index if not exists idx_recurring_next_due on public.recurring_rules(next_due_date) where is_active = true;

-- Audit Trigger Function
create or replace function public.trigger_set_audit_fields()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    if new.created_by is null then
       new.created_by := auth.uid();
    end if;
    -- If created_by is still null (e.g. cron), allow it or handle?
    -- If auth.uid() is null (cron), created_by might be null.
    -- In cron case, we pass creator_id explicitly in insert.

    if new.updated_by is null then
       new.updated_by := new.created_by;
    end if;
  elsif (TG_OP = 'UPDATE') then
    -- Prevent changing created_by/created_at
    new.created_by := old.created_by;
    new.created_at := old.created_at;

    -- Set updated info
    new.updated_by := auth.uid();
    -- Note: If auth.uid() is null (cron updating), we might want to preserve old or set to specific system ID.
    -- For now, keep as is.
    new.updated_at := now();
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Attach Trigger
drop trigger if exists set_expenses_audit_fields on public.expenses;
create trigger set_expenses_audit_fields
  before insert or update on public.expenses
  for each row
  execute function public.trigger_set_audit_fields();

-- Helper to create expense from JSON
create or replace function public.create_expense_transaction_from_json(payload jsonb, creator_id uuid)
returns uuid as $$
declare
  new_expense_id uuid;
  p_group_id uuid;
  p_title text;
  p_amount numeric;
  p_currency text;
  p_notes text;
begin
  p_group_id := (payload->>'group_id')::uuid;
  p_title := payload->>'title';
  p_amount := (payload->>'amount')::numeric;
  p_currency := payload->>'currency';
  p_notes := payload->>'notes';

  -- If group_id in payload is null, try to use from recurring rule?
  -- The payload should contain it ideally.

  insert into public.expenses (group_id, created_by, title, amount, currency, notes, occurred_at)
  values (p_group_id, creator_id, p_title, p_amount, p_currency, p_notes, now())
  returning id into new_expense_id;

  return new_expense_id;
end;
$$ language plpgsql security definer;

-- Processor Function
create or replace function public.process_due_recurring_rules()
returns void as $$
declare
  r record;
  new_date timestamptz;
  execution_time timestamptz := now();
begin
  for r in
    select * from public.recurring_rules
    where is_active = true and next_due_date <= execution_time
    for update skip locked
  loop
    begin
      -- Execute
      perform public.create_expense_transaction_from_json(r.expense_payload, r.user_id);

      -- Reschedule
      if r.frequency = 'DAILY' then
        new_date := r.next_due_date + interval '1 day';
      elsif r.frequency = 'WEEKLY' then
        new_date := r.next_due_date + interval '1 week';
      elsif r.frequency = 'MONTHLY' then
        new_date := r.next_due_date + interval '1 month';
      elsif r.frequency = 'YEARLY' then
        new_date := r.next_due_date + interval '1 year';
      else
         new_date := r.next_due_date + interval '1 day'; -- Fallback
      end if;

      update public.recurring_rules
      set next_due_date = new_date
      where id = r.id;

    exception when others then
      raise warning 'Failed to process recurring rule %: %', r.id, sqlerrm;
    end;
  end loop;
end;
$$ language plpgsql security definer;

-- Schedule Cron (Hourly)
-- Using distinct job name to avoid duplicates
select cron.schedule('process_recurring_expenses_hourly', '0 * * * *', 'select public.process_due_recurring_rules()');
