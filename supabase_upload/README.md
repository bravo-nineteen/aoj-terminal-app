Supabase Upload Workflow

This folder gives you a direct path to push DB changes and upload AOJ event JSON exports to Supabase.

Files
- .env.example: environment variable template.
- create_aoj_events_table.sql: SQL for the aoj_events table.
- setup_supabase_cli.sh: prepares Supabase CLI via npx.
- db_push.sh: links project and runs supabase db push.
- upload_event_json.sh: upserts one event export JSON into public.aoj_events.

Setup
1. Copy env template:
   cp supabase_upload/.env.example supabase_upload/.env
2. Fill values in supabase_upload/.env:
   - SUPABASE_URL
   - SUPABASE_SERVICE_ROLE_KEY
   - SUPABASE_PROJECT_REF (required for linked/pooler path)
   - SUPABASE_DB_PASSWORD
   - SUPABASE_DB_URL (optional direct URI, bypasses pooler in db_push.sh)

Apply SQL once in Supabase SQL Editor
1. Open create_aoj_events_table.sql
2. Run it in your project SQL Editor

Run scripts
1. Prepare CLI (only once):
   cd supabase_upload && ./setup_supabase_cli.sh
2. Log in to Supabase CLI (once per machine):
   npx --yes supabase login
3. Push migrations:
   cd supabase_upload && ./db_push.sh
4. Upload event JSON file exported by this app:
   cd supabase_upload && ./upload_event_json.sh /path/to/EventName_export.json

How sync works now
- db_push.sh auto-initializes a local supabase folder if missing.
- db_push.sh auto-creates a migration from create_aoj_events_table.sql.
- db_push.sh creates a new timestamped migration whenever create_aoj_events_table.sql changes.
- db_push.sh runs link and db push from repository root, which Supabase CLI expects.
- db_push.sh uses non-interactive push (--yes) to avoid hanging at a Y/n prompt.
- If SUPABASE_DB_URL is set, db_push.sh uses direct `supabase db push --db-url ...` and skips `supabase link`.

Direct DB URI example
- Use this format for SUPABASE_DB_URL:
   postgresql://postgres.<project_ref>:<percent_encoded_password>@db.<project_ref>.supabase.co:5432/postgres?sslmode=require
- Replace `<project_ref>` with your project ref (for example, uvixlrhcjojezhqmgnxk).
- Percent-encode password characters like `%` as `%25` and `@` as `%40`.

Notes
- upload_event_json.sh requires JSON with at least id and name fields.
- Service role key is powerful. Keep supabase_upload/.env private and never commit it.
