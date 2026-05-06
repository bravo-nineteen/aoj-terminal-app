-- Add attachment columns to messages table
alter table public.messages
  add column if not exists attachment_url text,
  add column if not exists attachment_type text,   -- 'image' | 'file'
  add column if not exists attachment_name text;

-- Storage bucket for message attachments (public, 50 MB limit)
insert into storage.buckets (id, name, public, file_size_limit)
values ('message-attachments', 'message-attachments', true, 52428800)
on conflict (id) do nothing;

-- RLS policies for the storage bucket
create policy "Public read message attachments"
  on storage.objects for select
  using (bucket_id = 'message-attachments');

create policy "Insert message attachments"
  on storage.objects for insert
  with check (bucket_id = 'message-attachments');

-- 90-day retention cleanup function
-- Schedule via pg_cron or call manually: select public.cleanup_old_message_attachments();
create or replace function public.cleanup_old_message_attachments()
returns void
language plpgsql
security definer
as $$
begin
  -- Remove files from storage
  delete from storage.objects
  where bucket_id = 'message-attachments'
    and created_at < now() - interval '90 days';

  -- Null out references in messages (message text stays)
  update public.messages
  set
    attachment_url  = null,
    attachment_type = null,
    attachment_name = null
  where created_at < now() - interval '90 days'
    and attachment_url is not null;
end;
$$;
