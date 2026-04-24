create table if not exists public.messages (
  id text primary key,
  sender text not null default '',
  body text not null default '',
  event_id text,
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_event_id on public.messages(event_id);
create index if not exists idx_messages_created_at on public.messages(created_at);
