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

drop trigger if exists trg_aoj_events_updated_at on public.aoj_events;
create trigger trg_aoj_events_updated_at
before update on public.aoj_events
for each row
execute function public.set_aoj_events_updated_at();

alter table public.aoj_events enable row level security;

-- Service-role uploads bypass RLS. If anon/auth users should read rows, enable this policy.
create policy if not exists "aoj_events_read_all"
on public.aoj_events
for select
using (true);
