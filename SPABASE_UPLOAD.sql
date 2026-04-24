-- Supabase SQL setup for AOJ Terminal sync and JSON uploads.
-- Run this in the Supabase SQL editor.

create table if not exists public.app_config (
  key text primary key,
  value text not null default ''
);

create table if not exists public.events (
  id text primary key,
  name text not null default '',
  venue text not null default '',
  date text not null default '',
  time text not null default '',
  notes text not null default '',
  ticket_cost_per_person text not null default '0',
  training_trainer text not null default '',
  lunch_options jsonb not null default '[]',
  field_map_base64 text,
  game_modes jsonb not null default '[]',
  accounting_notes jsonb not null default '[]',
  updated_at timestamptz not null default now()
);

alter table if exists public.events add column if not exists id text;
alter table if exists public.events add column if not exists name text;
alter table if exists public.events add column if not exists venue text;
alter table if exists public.events add column if not exists date text;
alter table if exists public.events add column if not exists time text;
alter table if exists public.events add column if not exists notes text;
alter table if exists public.events add column if not exists ticket_cost_per_person text;
alter table if exists public.events add column if not exists training_trainer text;
alter table if exists public.events add column if not exists lunch_options jsonb;
alter table if exists public.events add column if not exists field_map_base64 text;
alter table if exists public.events add column if not exists game_modes jsonb;
alter table if exists public.events add column if not exists accounting_notes jsonb;
alter table if exists public.events add column if not exists updated_at timestamptz;

alter table if exists public.events
  alter column id type text using id::text,
  alter column name type text using name::text,
  alter column venue type text using venue::text,
  alter column date type text using date::text,
  alter column time type text using time::text,
  alter column notes type text using notes::text,
  alter column ticket_cost_per_person type text using ticket_cost_per_person::text,
  alter column training_trainer type text using training_trainer::text,
  alter column field_map_base64 type text using field_map_base64::text;

update public.events
set
  name = coalesce(name::text, ''),
  venue = coalesce(venue::text, ''),
  date = coalesce(date::text, ''),
  time = coalesce(time::text, ''),
  notes = coalesce(notes::text, ''),
  ticket_cost_per_person = coalesce(ticket_cost_per_person::text, '0'),
  training_trainer = coalesce(training_trainer::text, ''),
  lunch_options = coalesce(lunch_options, '[]'::jsonb),
  game_modes = coalesce(game_modes, '[]'::jsonb),
  accounting_notes = coalesce(accounting_notes, '[]'::jsonb),
  updated_at = coalesce(updated_at, now());

alter table if exists public.events
  alter column id set not null,
  alter column name set default '',
  alter column name set not null,
  alter column venue set default '',
  alter column venue set not null,
  alter column date set default '',
  alter column date set not null,
  alter column time set default '',
  alter column time set not null,
  alter column notes set default '',
  alter column notes set not null,
  alter column ticket_cost_per_person set default '0',
  alter column ticket_cost_per_person set not null,
  alter column training_trainer set default '',
  alter column training_trainer set not null,
  alter column lunch_options set default '[]'::jsonb,
  alter column lunch_options set not null,
  alter column game_modes set default '[]'::jsonb,
  alter column game_modes set not null,
  alter column accounting_notes set default '[]'::jsonb,
  alter column accounting_notes set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'events_pkey'
  ) then
    alter table if exists public.events add primary key (id);
  end if;
end
$$;

create table if not exists public.bookings (
  id text primary key,
  event_id text not null,
  booking_id text not null default '',
  booking_date text not null default '',
  first_name text not null default '',
  last_name text not null default '',
  email text not null default '',
  phone text not null default '',
  event text not null default '',
  total text not null default '0',
  total_paid text not null default '0',
  transaction_id text not null default '',
  payment_method text not null default '',
  payment_status text not null default '',
  check_in_status text not null default '',
  notes text not null default '',
  needs_pickup boolean not null default false,
  needs_training boolean not null default false,
  guest_names text not null default '',
  language_preference text not null default '',
  lunch_order_ids jsonb not null default '[]',
  ticket_ids jsonb not null default '[]',
  sales jsonb not null default '[]',
  payments jsonb not null default '[]',
  updated_at timestamptz not null default now()
);

create table if not exists public.tickets (
  id text primary key,
  event_id text not null,
  booking_id text not null default '',
  booking_name text not null default '',
  ticket_name text not null default '',
  price text not null default '0',
  spaces text not null default '1',
  status text not null default 'Active',
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id text primary key,
  event_id text not null,
  first_name text not null default '',
  last_name text not null default '',
  username text not null default '',
  date_of_birth text not null default '',
  gender text not null default '',
  telephone text not null default '',
  email text not null default '',
  membership_level text not null default 'Regular',
  rating integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.schedule (
  id text primary key,
  event_id text not null,
  time text not null default '',
  activity text not null default '',
  location text not null default '',
  notes text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id text primary key,
  event_id text not null,
  item text not null default '',
  amount text not null default '0',
  note text not null default '',
  date text not null default '',
  category text not null default '',
  updated_at timestamptz not null default now()
);

create index if not exists idx_bookings_event_id on public.bookings(event_id);
create index if not exists idx_tickets_event_id on public.tickets(event_id);
create index if not exists idx_members_event_id on public.members(event_id);
create index if not exists idx_schedule_event_id on public.schedule(event_id);
create index if not exists idx_expenses_event_id on public.expenses(event_id);

do $$
declare
  fk_record record;
  column_record record;
begin
  create temporary table if not exists _aoj_fk_backup (
    table_schema text not null,
    table_name text not null,
    constraint_name text not null,
    constraint_definition text not null
  ) on commit drop;

  create temporary table if not exists _aoj_fk_columns (
    table_schema text not null,
    table_name text not null,
    column_name text not null
  ) on commit drop;

  truncate table _aoj_fk_backup;
  truncate table _aoj_fk_columns;

  insert into _aoj_fk_backup (table_schema, table_name, constraint_name, constraint_definition)
  select
    source_ns.nspname,
    source_cls.relname,
    constraint_info.conname,
    pg_get_constraintdef(constraint_info.oid)
  from pg_constraint constraint_info
  join pg_class source_cls on source_cls.oid = constraint_info.conrelid
  join pg_namespace source_ns on source_ns.oid = source_cls.relnamespace
  join pg_class target_cls on target_cls.oid = constraint_info.confrelid
  join pg_namespace target_ns on target_ns.oid = target_cls.relnamespace
  where constraint_info.contype = 'f'
    and target_ns.nspname = 'public'
    and target_cls.relname in ('events', 'bookings', 'tickets', 'members', 'schedule', 'expenses');

  insert into _aoj_fk_columns (table_schema, table_name, column_name)
  select distinct
    source_ns.nspname,
    source_cls.relname,
    source_att.attname
  from pg_constraint constraint_info
  join pg_class source_cls on source_cls.oid = constraint_info.conrelid
  join pg_namespace source_ns on source_ns.oid = source_cls.relnamespace
  join pg_class target_cls on target_cls.oid = constraint_info.confrelid
  join pg_namespace target_ns on target_ns.oid = target_cls.relnamespace
  join unnest(constraint_info.conkey) with ordinality as source_key(attnum, ordinality)
    on true
  join unnest(constraint_info.confkey) with ordinality as target_key(attnum, ordinality)
    on source_key.ordinality = target_key.ordinality
  join pg_attribute source_att
    on source_att.attrelid = source_cls.oid
   and source_att.attnum = source_key.attnum
  join information_schema.columns columns_info
    on columns_info.table_schema = source_ns.nspname
   and columns_info.table_name = source_cls.relname
   and columns_info.column_name = source_att.attname
  where constraint_info.contype = 'f'
    and target_ns.nspname = 'public'
    and target_cls.relname in ('events', 'bookings', 'tickets', 'members', 'schedule', 'expenses')
    and columns_info.udt_name = 'uuid';

  for fk_record in
    select * from _aoj_fk_backup
  loop
    execute format(
      'alter table %I.%I drop constraint if exists %I',
      fk_record.table_schema,
      fk_record.table_name,
      fk_record.constraint_name
    );
  end loop;

  for column_record in
    select distinct table_schema, table_name, column_name
    from information_schema.columns
    where table_schema = 'public'
      and (
        (table_name = 'events' and column_name = 'id') or
        (table_name = 'bookings' and column_name in ('id', 'event_id')) or
        (table_name = 'tickets' and column_name in ('id', 'event_id')) or
        (table_name = 'members' and column_name in ('id', 'event_id')) or
        (table_name = 'schedule' and column_name in ('id', 'event_id')) or
        (table_name = 'expenses' and column_name in ('id', 'event_id')) or
        (table_name = 'aoj_events' and column_name = 'id')
      )
      and udt_name = 'uuid'
    union
    select table_schema, table_name, column_name
    from _aoj_fk_columns
  loop
    execute format(
      'alter table %I.%I alter column %I type text using %I::text',
      column_record.table_schema,
      column_record.table_name,
      column_record.column_name,
      column_record.column_name
    );
  end loop;

  for fk_record in
    select * from _aoj_fk_backup
  loop
    execute format(
      'alter table %I.%I add constraint %I %s',
      fk_record.table_schema,
      fk_record.table_name,
      fk_record.constraint_name,
      fk_record.constraint_definition
    );
  end loop;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'bookings_event_id_fkey'
  ) then
    alter table if exists public.bookings
      add constraint bookings_event_id_fkey
      foreign key (event_id) references public.events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'tickets_event_id_fkey'
  ) then
    alter table if exists public.tickets
      add constraint tickets_event_id_fkey
      foreign key (event_id) references public.events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'members_event_id_fkey'
  ) then
    alter table if exists public.members
      add constraint members_event_id_fkey
      foreign key (event_id) references public.events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'schedule_event_id_fkey'
  ) then
    alter table if exists public.schedule
      add constraint schedule_event_id_fkey
      foreign key (event_id) references public.events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'expenses_event_id_fkey'
  ) then
    alter table if exists public.expenses
      add constraint expenses_event_id_fkey
      foreign key (event_id) references public.events(id) on delete cascade;
  end if;
end
$$;

create table if not exists public.aoj_events (
  id text primary key,
  name text not null default '',
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create or replace function public.set_aoj_events_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

insert into public.app_config (key, value)
values ('schema_version', '2026-04-24')
on conflict (key)
do update set value = excluded.value;

drop trigger if exists trg_aoj_events_updated_at on public.aoj_events;
create trigger trg_aoj_events_updated_at
before update on public.aoj_events
for each row
execute function public.set_aoj_events_updated_at();

alter table public.aoj_events enable row level security;

-- Add read policies only if anon or authenticated clients should read aoj_events.

create table if not exists public.messages (
  id text primary key,
  sender text not null default '',
  body text not null default '',
  event_id text,
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_event_id on public.messages(event_id);
create index if not exists idx_messages_created_at on public.messages(created_at);

alter table if exists public.messages enable row level security;

grant select, insert on table public.messages to anon, authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'messages'
      and policyname = 'messages_select_all'
  ) then
    create policy "messages_select_all"
    on public.messages
    for select
    to anon, authenticated
    using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'messages'
      and policyname = 'messages_insert_all'
  ) then
    create policy "messages_insert_all"
    on public.messages
    for insert
    to anon, authenticated
    with check (true);
  end if;
end;
$$;