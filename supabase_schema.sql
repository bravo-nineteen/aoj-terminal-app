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
  field_map_base64      text,
  game_modes            jsonb not null default '[]'
);

-- ── bookings ─────────────────────────────────────────────────────────────────
create table if not exists bookings (
  id                  text primary key,
  event_id            text not null references events(id) on delete cascade,
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
  ticket_ids          jsonb not null default '[]',
  sales               jsonb not null default '[]',
  payments            jsonb not null default '[]'
);

-- ── tickets ──────────────────────────────────────────────────────────────────
create table if not exists tickets (
  id           text primary key,
  event_id     text not null references events(id) on delete cascade,
  booking_id   text not null default '',
  booking_name text not null default '',
  ticket_name  text not null default '',
  price        text not null default '0',
  spaces       text not null default '1',
  status       text not null default 'Active'
);

-- ── members ──────────────────────────────────────────────────────────────────
create table if not exists members (
  id               text primary key,
  event_id         text not null references events(id) on delete cascade,
  first_name       text not null default '',
  last_name        text not null default '',
  username         text not null default '',
  date_of_birth    text not null default '',
  gender           text not null default '',
  telephone        text not null default '',
  email            text not null default '',
  membership_level text not null default 'Regular',
  rating           integer not null default 0
);

-- ── schedule ─────────────────────────────────────────────────────────────────
create table if not exists schedule (
  id       text primary key,
  event_id text not null references events(id) on delete cascade,
  time     text not null default '',
  activity text not null default '',
  location text not null default '',
  notes    text not null default ''
);

-- ── expenses ─────────────────────────────────────────────────────────────────
create table if not exists expenses (
  id       text primary key,
  event_id text not null references events(id) on delete cascade,
  item     text not null default '',
  amount   text not null default '0',
  note     text not null default '',
  date     text not null default '',
  category text not null default ''
);
