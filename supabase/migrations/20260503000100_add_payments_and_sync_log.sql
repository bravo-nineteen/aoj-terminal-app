create table if not exists public.payments (
  id text primary key,
  event_id text not null,
  booking_row_id text not null default '',
  booking_id text not null default '',
  payment_id text not null default '',
  amount text not null default '0',
  method text not null default '',
  note text not null default '',
  date text not null default '',
  updated_at timestamptz not null default now()
);

-- Ensure event_id column exists (in case table was created without it)
alter table if exists public.payments
  add column if not exists event_id text;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'payments'
      and column_name = 'event_id'
  ) then
    create index if not exists idx_payments_event_id on public.payments(event_id);
  end if;
end
$$;

create table if not exists public.sync_log (
  id bigserial primary key,
  operation text not null default '',
  started_at text not null default '',
  completed_at text not null default '',
  local_events integer not null default 0,
  cloud_events integer not null default 0,
  merged_events integer not null default 0,
  conflicts integer not null default 0,
  last_error text not null default '',
  last_error_code text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.deleted_records (
  id text primary key,
  table_name text not null,
  event_id text not null,
  record_id text not null,
  deleted_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_sync_log_created_at on public.sync_log(created_at desc);
create index if not exists idx_deleted_records_table_event on public.deleted_records(table_name, event_id);
create index if not exists idx_deleted_records_record on public.deleted_records(record_id);
create unique index if not exists uq_deleted_records_table_event_record
  on public.deleted_records(table_name, event_id, record_id);

-- ── MIGRATION: Consolidate payments to single table source of truth ──
-- This migration addresses duplicate payment storage:
-- Problem: payments stored in TWO places - bookings.payments (JSONB) AND payments table
-- Solution: Migrate all payments to payments table, keep derived fields in bookings
-- Rationale: Single source of truth prevents sync duplicates

-- Step 0: Temporarily drop the foreign key constraint
alter table if exists public.payments
  drop constraint if exists payments_booking_id_fkey;

do $$
declare
  booking_row record;
  payment_obj jsonb;
  payment_id_exists boolean;
  skipped_count integer := 0;
begin
  -- Step 1: Migrate payments from bookings.payments JSONB array to payments table
  for booking_row in
    select id::text, booking_id, payments
    from public.bookings
    where payments is not null and jsonb_array_length(payments) > 0
  loop
    for payment_obj in
      select jsonb_array_elements(booking_row.payments)
    loop
      -- Check if this payment already exists in payments table by id
      select exists(
        select 1 from public.payments
        where id = uuid_generate_v5('00000000-0000-0000-0000-000000000000'::uuid, (payment_obj->>'id')::text)
      ) into payment_id_exists;

      -- Only insert if not already present
      if not payment_id_exists then
        insert into public.payments (
          id,
          event_id,
          booking_row_id,
          booking_id,
          payment_id,
          amount,
          method,
          note,
          date,
          updated_at
        ) values (
          uuid_generate_v5('00000000-0000-0000-0000-000000000000'::uuid, (payment_obj->>'id')::text),
          booking_row.id,
          booking_row.id,
          booking_row.booking_id,
          (payment_obj->>'id')::text,
          (payment_obj->>'amount')::integer,
          (payment_obj->>'method')::text,
          (payment_obj->>'note')::text,
          (payment_obj->>'date')::text,
          now()
        )
        on conflict (id) do nothing;
      end if;
    end loop;
  end loop;
  
  raise notice 'Payment migration complete.';
end
$$;

-- Step 0b: Note - FK constraint NOT recreated because booking_id is not unique in bookings table
-- The payments table now has orphaned records that won't have valid FK constraints
-- These should be cleaned up by application logic

-- Step 2: Recalculate and update booking totals from payments table
-- This ensures bookings.total, bookings.totalPaid, bookings.paymentStatus
-- are always derived from the authoritative payments table
do $$
declare
  booking_row record;
  calculated_total_paid numeric;
begin
  for booking_row in
    select id::text, booking_id
    from public.bookings
  loop
    -- Calculate total paid from payments table
    select coalesce(sum((amount)::numeric), 0)
    into calculated_total_paid
    from public.payments
    where booking_row_id = booking_row.id
      and method != 'Refund'
      and method != 'refund';

    -- Update total_paid in bookings
    update public.bookings
    set total_paid = calculated_total_paid::text
    where id::text = booking_row.id;
  end loop;
end
$$;

-- Step 3: Create a view to detect duplicates for monitoring
-- This helps identify bookings with duplicate payments
drop view if exists public.v_payment_duplicates;

create or replace view v_payment_duplicates as
select
  b.id as booking_row_id,
  b.id as event_id,
  b.booking_id,
  count(distinct p.id) as payment_count_in_table,
  jsonb_array_length(b.payments) as payment_count_in_jsonb,
  (count(distinct p.id) - jsonb_array_length(b.payments)) as difference,
  array_agg(distinct p.id::text) as payment_ids_in_table,
  b.payments as payment_jsonb
from public.bookings b
left join public.payments p on p.booking_row_id = b.id::text
where b.payments is not null and jsonb_array_length(b.payments) > 0
group by b.id, b.booking_id, b.payments
having count(distinct p.id) != jsonb_array_length(b.payments)
  or count(distinct p.id) > 0;

-- Step 4: Drop the JSONB payments column from bookings (optional - keep for now for compatibility)
-- To be deprecated after confirming all code uses payments table
-- alter table if exists public.bookings drop column if exists payments;

-- Step 5: Add constraint to ensure booking_row_id references exist
-- Note: Skipping FK constraint due to type mismatch (booking_row_id is text)
-- The application must ensure referential integrity when deleting bookings

-- Step 6: Add index for payment deduplication checks
create index if not exists idx_payments_booking_row_id on public.payments(booking_row_id);
create index if not exists idx_payments_dedup_key on public.payments(booking_row_id, method, amount, date);

