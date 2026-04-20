#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required"
  exit 1
fi

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in supabase_upload/.env"
  exit 1
fi

EVENT_FILE="${1:-}"
if [[ -z "${EVENT_FILE}" ]]; then
  echo "Usage: ./upload_event_json.sh /absolute/or/relative/path/to/event_export.json"
  exit 1
fi

if [[ ! -f "${EVENT_FILE}" ]]; then
  echo "File not found: ${EVENT_FILE}"
  exit 1
fi

EVENT_ID="$(jq -r '.id // empty' "${EVENT_FILE}")"
EVENT_NAME="$(jq -r '.name // ""' "${EVENT_FILE}")"

if [[ -z "${EVENT_ID}" ]]; then
  echo "JSON file is missing required field: id"
  exit 1
fi

BODY="$(jq -nc --arg id "${EVENT_ID}" --arg name "${EVENT_NAME}" --slurpfile payload "${EVENT_FILE}" '[{id:$id,name:$name,payload:$payload[0]}]')"

RESPONSE="$(curl -sS -w "\n%{http_code}" \
  -X POST "${SUPABASE_URL%/}/rest/v1/aoj_events?on_conflict=id" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=representation" \
  -d "${BODY}")"

HTTP_CODE="$(printf '%s' "${RESPONSE}" | tail -n1)"
HTTP_BODY="$(printf '%s' "${RESPONSE}" | sed '$d')"

if [[ "${HTTP_CODE}" -lt 200 || "${HTTP_CODE}" -ge 300 ]]; then
  echo "Upload failed with HTTP ${HTTP_CODE}"
  echo "${HTTP_BODY}"
  exit 1
fi

echo "Upload succeeded"
echo "${HTTP_BODY}" | jq .
