#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

supabase_cmd() {
  npx --yes supabase "$@"
}

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to run supabase via npx"
  exit 1
fi

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "SUPABASE_PROJECT_REF is missing. Add it to supabase_upload/.env"
  exit 1
fi

supabase_cmd link --project-ref "${SUPABASE_PROJECT_REF}"
supabase_cmd db push
