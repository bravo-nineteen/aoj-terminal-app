alter table if exists events
  add column if not exists lunch_options jsonb not null default '[]';

alter table if exists bookings
  add column if not exists lunch_order_ids jsonb not null default '[]';
