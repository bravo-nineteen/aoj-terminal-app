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
