-- Run this in the Supabase SQL Editor to set up the sync tables.
-- All tables use RLS disabled for simplicity; enable and configure as needed.

-- ── app_config ───────────────────────────────────────────────────────────────
create table if not exists app_config (
  key   text primary key,
  value text not null default ''
);

-- ── events ───────────────────────────────────────────────────────────────────
create table if not exists events (
  id                    text primary key,
  name                  text not null default '',
  venue                 text not null default '',
  date                  text not null default '',
  time                  text not null default '',
  notes                 text not null default '',
  ticket_cost_per_person text not null default '0',
  training_trainer      text not null default '',
  lunch_options         jsonb not null default '[]',
  field_map_base64      text,
  game_modes            jsonb not null default '[]',
  accounting_notes      jsonb not null default '[]',
  updated_at            timestamptz not null default now()
);

-- ── bookings ─────────────────────────────────────────────────────────────────
create table if not exists bookings (
  id                  text primary key,
  event_id            text not null,
  booking_id          text not null default '',
  booking_date        text not null default '',
  first_name          text not null default '',
  last_name           text not null default '',
  email               text not null default '',
  phone               text not null default '',
  event               text not null default '',
  total               text not null default '0',
  total_paid          text not null default '0',
  transaction_id      text not null default '',
  payment_method      text not null default '',
  payment_status      text not null default '',
  check_in_status     text not null default '',
  notes               text not null default '',
  needs_pickup        boolean not null default false,
  needs_training      boolean not null default false,
  guest_names         text not null default '',
  language_preference text not null default '',
  lunch_order_ids     jsonb not null default '[]',
  ticket_ids          jsonb not null default '[]',
  sales               jsonb not null default '[]',
  payments            jsonb not null default '[]',
  updated_at          timestamptz not null default now()
);

-- ── tickets ──────────────────────────────────────────────────────────────────
create table if not exists tickets (
  id           text primary key,
  event_id     text not null,
  booking_id   text not null default '',
  booking_name text not null default '',
  ticket_name  text not null default '',
  price        text not null default '0',
  spaces       text not null default '1',
  status       text not null default 'Active',
  updated_at   timestamptz not null default now()
);

-- ── members ──────────────────────────────────────────────────────────────────
create table if not exists members (
  id               text primary key,
  event_id         text not null,
  first_name       text not null default '',
  last_name        text not null default '',
  username         text not null default '',
  date_of_birth    text not null default '',
  gender           text not null default '',
  telephone        text not null default '',
  email            text not null default '',
  membership_level text not null default 'Regular',
  rating           integer not null default 0,
  updated_at       timestamptz not null default now()
);

-- ── schedule ─────────────────────────────────────────────────────────────────
create table if not exists schedule (
  id       text primary key,
  event_id text not null,
  time     text not null default '',
  activity text not null default '',
  location text not null default '',
  notes    text not null default '',
  updated_at timestamptz not null default now()
);

-- ── expenses ─────────────────────────────────────────────────────────────────
create table if not exists expenses (
  id       text primary key,
  event_id text not null,
  item     text not null default '',
  amount   text not null default '0',
  note     text not null default '',
  date     text not null default '',
  category text not null default '',
  notes    jsonb not null default '[]',
  updated_at timestamptz not null default now()
);

-- ── messages ─────────────────────────────────────────────────────────────────
create table if not exists messages (
  id         text primary key,
  sender     text not null default '',
  body       text not null default '',
  event_id   text,
  created_at timestamptz not null default now()
);

create index if not exists idx_bookings_event_id on bookings(event_id);
create index if not exists idx_tickets_event_id on tickets(event_id);
create index if not exists idx_members_event_id on members(event_id);
create index if not exists idx_schedule_event_id on schedule(event_id);
create index if not exists idx_expenses_event_id on expenses(event_id);

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
        (table_name = 'expenses' and column_name in ('id', 'event_id'))
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
    alter table if exists bookings
      add constraint bookings_event_id_fkey
      foreign key (event_id) references events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'tickets_event_id_fkey'
  ) then
    alter table if exists tickets
      add constraint tickets_event_id_fkey
      foreign key (event_id) references events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'members_event_id_fkey'
  ) then
    alter table if exists members
      add constraint members_event_id_fkey
      foreign key (event_id) references events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'schedule_event_id_fkey'
  ) then
    alter table if exists schedule
      add constraint schedule_event_id_fkey
      foreign key (event_id) references events(id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'expenses_event_id_fkey'
  ) then
    alter table if exists expenses
      add constraint expenses_event_id_fkey
      foreign key (event_id) references events(id) on delete cascade;
  end if;
end
$$;
