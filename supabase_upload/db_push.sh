#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SQL_FILE="${SCRIPT_DIR}/create_aoj_events_table.sql"
MIGRATIONS_DIR="${REPO_ROOT}/supabase/migrations"

supabase_cmd() {
  npx --yes supabase "$@"
}

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
fi

if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  export SUPABASE_ACCESS_TOKEN
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to run supabase via npx"
  exit 1
fi

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "SUPABASE_PROJECT_REF is missing. Add it to supabase_upload/.env"
  exit 1
fi

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "Missing SQL file: ${SQL_FILE}"
  exit 1
fi

if [[ ! -d "${REPO_ROOT}/supabase" ]]; then
  echo "Initializing Supabase project in ${REPO_ROOT}/supabase"
  (
    cd "${REPO_ROOT}"
    supabase_cmd init
  )
fi

mkdir -p "${MIGRATIONS_DIR}"

if ! find "${MIGRATIONS_DIR}" -maxdepth 1 -type f -name '*aoj_events*.sql' | grep -q .; then
  ts="$(date +%Y%m%d%H%M%S)"
  migration_file="${MIGRATIONS_DIR}/${ts}_aoj_events.sql"
  cp "${SQL_FILE}" "${migration_file}"
  echo "Created migration: ${migration_file}"
fi

(
  cd "${REPO_ROOT}"
  if [[ -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
    supabase_cmd link --project-ref "${SUPABASE_PROJECT_REF}" --password "${SUPABASE_DB_PASSWORD}"
  else
    supabase_cmd link --project-ref "${SUPABASE_PROJECT_REF}"
  fi
  supabase_cmd db push
)
