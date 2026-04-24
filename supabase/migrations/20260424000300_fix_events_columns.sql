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

insert into public.app_config (key, value)
values ('schema_version', '2026-04-24')
on conflict (key)
do update set value = excluded.value;
