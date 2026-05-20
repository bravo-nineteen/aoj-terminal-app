-- Persist editable ticket count used for event cost-basis math.
alter table if exists public.events
  add column if not exists ticket_count_override text;

update public.events
set ticket_count_override = ''
where ticket_count_override is null;

alter table if exists public.events
  alter column ticket_count_override set default '';

alter table if exists public.events
  alter column ticket_count_override set not null;
