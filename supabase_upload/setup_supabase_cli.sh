#!/usr/bin/env bash
set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to run supabase via npx"
  exit 1
fi

echo "Preparing Supabase CLI via npx..."
npx --yes supabase --version
