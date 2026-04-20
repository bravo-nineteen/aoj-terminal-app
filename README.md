# aoj-terminal-app

Event management terminal app built with Flutter.

## Development

1. Install Flutter SDK and run `flutter pub get`.
2. Start the app with `flutter run -d windows` (or another target device).

## Sync

The app supports Supabase-based sync merge between devices.
For production, pass credentials via dart-defines:

`--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

Use the project base URL only (for example, `https://your-project-id.supabase.co`).
Do not include API path suffixes like `/rest/v1`.
