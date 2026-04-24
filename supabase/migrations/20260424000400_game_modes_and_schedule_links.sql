alter table if exists public.schedule
  add column if not exists game_mode_title text;

update public.schedule
set game_mode_title = coalesce(game_mode_title::text, '');

alter table if exists public.schedule
  alter column game_mode_title set default '',
  alter column game_mode_title set not null;

create table if not exists public.game_modes (
  id text primary key,
  event_id text not null,
  data jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

create index if not exists idx_game_modes_event_id on public.game_modes(event_id);
