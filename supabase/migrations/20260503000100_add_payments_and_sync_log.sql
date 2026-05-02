create table if not exists public.payments (
  id text primary key,
  event_id text not null,
  booking_row_id text not null default '',
  booking_id text not null default '',
  payment_id text not null default '',
  amount text not null default '0',
  method text not null default '',
  note text not null default '',
  date text not null default '',
  updated_at timestamptz not null default now()
);

alter table if exists public.payments
  add column if not exists event_id text not null default '',
  add column if not exists booking_row_id text not null default '',
  add column if not exists booking_id text not null default '',
  add column if not exists payment_id text not null default '',
  add column if not exists amount text not null default '0',
  add column if not exists method text not null default '',
  add column if not exists note text not null default '',
  add column if not exists date text not null default '',
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'payments'
      and column_name = 'event_id'
  ) then
    create index if not exists idx_payments_event_id on public.payments(event_id);
  end if;
end
$$;

create table if not exists public.sync_log (
  id bigserial primary key,
  operation text not null default '',
  started_at text not null default '',
  completed_at text not null default '',
  local_events integer not null default 0,
  cloud_events integer not null default 0,
  merged_events integer not null default 0,
  conflicts integer not null default 0,
  last_error text not null default '',
  last_error_code text not null default '',
  created_at timestamptz not null default now()
);

alter table if exists public.sync_log
  add column if not exists operation text not null default '',
  add column if not exists started_at text not null default '',
  add column if not exists completed_at text not null default '',
  add column if not exists local_events integer not null default 0,
  add column if not exists cloud_events integer not null default 0,
  add column if not exists merged_events integer not null default 0,
  add column if not exists conflicts integer not null default 0,
  add column if not exists last_error text not null default '',
  add column if not exists last_error_code text not null default '',
  add column if not exists created_at timestamptz not null default now();

create index if not exists idx_sync_log_created_at on public.sync_log(created_at desc);
