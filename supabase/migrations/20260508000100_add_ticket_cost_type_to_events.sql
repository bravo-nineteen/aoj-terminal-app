-- Persist event ticket cost mode ('perPerson' or 'grandTotal').
alter table if exists public.events
  add column if not exists ticket_cost_type text;

update public.events
set ticket_cost_type = 'perPerson'
where ticket_cost_type is null or ticket_cost_type = '';

alter table if exists public.events
  alter column ticket_cost_type set default 'perPerson';

alter table if exists public.events
  alter column ticket_cost_type set not null;
