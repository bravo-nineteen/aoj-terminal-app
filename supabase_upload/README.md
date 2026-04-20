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
   - SUPABASE_PROJECT_REF

Apply SQL once in Supabase SQL Editor
1. Open create_aoj_events_table.sql
2. Run it in your project SQL Editor

Run scripts
1. Prepare CLI (only once):
   cd supabase_upload && ./setup_supabase_cli.sh
2. Push migrations (if you are using Supabase migrations):
   cd supabase_upload && ./db_push.sh
3. Upload event JSON file exported by this app:
   cd supabase_upload && ./upload_event_json.sh /path/to/EventName_export.json

Notes
- upload_event_json.sh requires JSON with at least id and name fields.
- Service role key is powerful. Keep supabase_upload/.env private and never commit it.
