#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   tool/ops/check_backup_provider_config_health.sh \
#     --project life-app-prod \
#     --dataset analytics_life_app_prod \
#     --webhook-url https://hooks.slack.com/services/XXX/YYY/ZZZ \
#     --markdown docs/review/backup-provider-health.md \
#     --json docs/review/backup-provider-health.json
#
# Notes:
# - Runs BigQuery metric query for backup_provider_options health.
# - Evaluates thresholds from docs/review/2026-03-07_backup-provider-options_observability.md.
# - Sends Slack notification when severity is warning/critical and webhook is set.
# - If dataset/location is unknown, run:
#   tool/ops/discover_backup_health_bq_source.sh --project <project-id>

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SQL_PATH_DEFAULT="${ROOT_DIR}/docs/review/2026-03-07_backup-provider-options_bigquery-metrics.sql"

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-${GCP_PROJECT_ID:-}}"
DATASET=""
SQL_PATH="${SQL_PATH_DEFAULT}"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
BQ_LOCATION="${BACKUP_HEALTH_BQ_LOCATION:-${BQ_LOCATION:-}}"
DRY_RUN="false"
MARKDOWN_OUT=""
JSON_OUT=""

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --project <id>        GCP project id (default: GOOGLE_CLOUD_PROJECT/GCP_PROJECT_ID)
  --dataset <name>      BigQuery dataset (default: analytics_<project>)
  --location <region>   BigQuery location (optional; e.g. US, asia-northeast3)
  --sql <path>          SQL template path (default: ${SQL_PATH_DEFAULT})
  --webhook-url <url>   Slack incoming webhook URL
  --dry-run             Print evaluation only; do not send webhook
  --markdown <path>     Write markdown evidence report
  --json <path>         Write raw metric row as JSON
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ID="${2:-}"
      shift 2
      ;;
    --dataset)
      DATASET="${2:-}"
      shift 2
      ;;
    --location)
      BQ_LOCATION="${2:-}"
      shift 2
      ;;
    --sql)
      SQL_PATH="${2:-}"
      shift 2
      ;;
    --webhook-url)
      WEBHOOK_URL="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --markdown)
      MARKDOWN_OUT="${2:-}"
      shift 2
      ;;
    --json)
      JSON_OUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Missing project id. Use --project or set GOOGLE_CLOUD_PROJECT." >&2
  exit 1
fi

if [[ -z "${DATASET}" ]]; then
  DATASET="analytics_${PROJECT_ID//-/_}"
fi

for cmd in bq jq awk; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Required command not found: ${cmd}" >&2
    exit 1
  fi
done

if [[ ! -f "${SQL_PATH}" ]]; then
  echo "SQL file not found: ${SQL_PATH}" >&2
  exit 1
fi

float_ge() {
  local left="$1"
  local right="$2"
  awk -v lhs="${left}" -v rhs="${right}" 'BEGIN { exit !((lhs+0) >= (rhs+0)) }'
}

float_percent() {
  local ratio="$1"
  awk -v x="${ratio}" 'BEGIN { printf "%.2f", (x+0) * 100 }'
}

write_failure_outputs() {
  local error_message="$1"
  local error_details="$2"

  if [[ -n "${JSON_OUT}" ]]; then
    mkdir -p "$(dirname "${JSON_OUT}")"
    jq -n \
      --arg status "error" \
      --arg project "${PROJECT_ID}" \
      --arg dataset "${DATASET}" \
      --arg location "${BQ_LOCATION:-auto}" \
      --arg error "${error_message}" \
      --arg details "${error_details}" \
      '{
        status: $status,
        project: $project,
        dataset: $dataset,
        location: $location,
        error: $error,
        details: $details
      }' > "${JSON_OUT}"
    echo "Wrote JSON metrics: ${JSON_OUT}"
  fi

  if [[ -n "${MARKDOWN_OUT}" ]]; then
    mkdir -p "$(dirname "${MARKDOWN_OUT}")"
    cat > "${MARKDOWN_OUT}" <<EOF
# Backup Provider Config Health Check

- Project: \`${PROJECT_ID}\`
- Dataset: \`${DATASET}\`
- Window End: \`unknown\`
- Severity: \`error\`
- Reason: ${error_message}

## Error

\`\`\`
${error_details}
\`\`\`
EOF
    echo "Wrote Markdown report: ${MARKDOWN_OUT}"
  fi
}

write_no_data_outputs() {
  if [[ -n "${JSON_OUT}" ]]; then
    mkdir -p "$(dirname "${JSON_OUT}")"
    jq -n \
      --arg status "no_data" \
      --arg project "${PROJECT_ID}" \
      --arg dataset "${DATASET}" \
      --arg location "${BQ_LOCATION:-auto}" \
      '{
        status: $status,
        project: $project,
        dataset: $dataset,
        location: $location
      }' > "${JSON_OUT}"
    echo "Wrote JSON metrics: ${JSON_OUT}"
  fi

  if [[ -n "${MARKDOWN_OUT}" ]]; then
    mkdir -p "$(dirname "${MARKDOWN_OUT}")"
    cat > "${MARKDOWN_OUT}" <<EOF
# Backup Provider Config Health Check

- Project: \`${PROJECT_ID}\`
- Dataset: \`${DATASET}\`
- Window End: \`unknown\`
- Severity: \`no_data\`
- Reason: No metric rows returned
EOF
    echo "Wrote Markdown report: ${MARKDOWN_OUT}"
  fi
}

SQL_QUERY="$(sed "s/<project_id>/${PROJECT_ID}/g" "${SQL_PATH}")"
SQL_QUERY="${SQL_QUERY//analytics_${PROJECT_ID}/$DATASET}"

query_args=(
  --project_id="${PROJECT_ID}"
  --use_legacy_sql=false
  --format=json
  --quiet
)

if [[ -n "${BQ_LOCATION}" ]]; then
  query_args+=(--location="${BQ_LOCATION}")
fi

bq_err_file="$(mktemp)"
set +e
RESULT_JSON="$(printf '%s\n' "${SQL_QUERY}" | bq query "${query_args[@]}" 2>"${bq_err_file}")"
bq_exit_code=$?
set -e

if [[ "${bq_exit_code}" -ne 0 ]]; then
  bq_error_excerpt="$(sed -n '1,120p' "${bq_err_file}" || true)"
  echo "BigQuery query failed." >&2
  echo "project=${PROJECT_ID} dataset=${DATASET} location=${BQ_LOCATION:-auto}" >&2
  printf '%s\n' "${bq_error_excerpt}" >&2
  echo "Tip: run tool/ops/discover_backup_health_bq_source.sh --project ${PROJECT_ID}" >&2
  write_failure_outputs "BigQuery query failed" "${bq_error_excerpt}"
  rm -f "${bq_err_file}"
  exit 1
fi
rm -f "${bq_err_file}"

if [[ "$(jq 'length' <<< "${RESULT_JSON}")" -eq 0 ]]; then
  echo "No metric rows returned."
  write_no_data_outputs
  exit 0
fi

ROW="$(jq '.[0]' <<< "${RESULT_JSON}")"
WINDOW_END="$(jq -r '.window_end_at // "unknown"' <<< "${ROW}")"
TOTAL_EVENTS="$(jq -r '.total_events // 0' <<< "${ROW}")"
PARSE_SUCCESS_RATE="$(jq -r '.parse_success_rate // 0' <<< "${ROW}")"
PARSED_WITH_DROPS_RATE="$(jq -r '.parsed_with_drops_rate // 0' <<< "${ROW}")"
DEFAULT_FALLBACK_RATE="$(jq -r '.default_fallback_rate // 0' <<< "${ROW}")"
HARD_FAILURE_RATE="$(jq -r '.hard_failure_rate // 0' <<< "${ROW}")"
HARD_FAILURE_EVENTS="$(jq -r '.hard_failure_events // 0' <<< "${ROW}")"
ROW_DROP_RATE="$(jq -r '.row_drop_rate // 0' <<< "${ROW}")"
MISSING_RATE="$(jq -r '.missing_rate // 0' <<< "${ROW}")"

SEVERITY="ok"
REASON="Within thresholds"

# Critical:
# - 30m hard failure >= 5 AND rate >= 20% (using latest aggregate row)
if [[ "${TOTAL_EVENTS}" -ge 25 ]] &&
  [[ "${HARD_FAILURE_EVENTS}" -ge 5 ]] &&
  float_ge "${HARD_FAILURE_RATE}" "0.20"; then
  SEVERITY="critical"
  REASON="Hard failure threshold breached"
elif [[ "${TOTAL_EVENTS}" -ge 100 ]] &&
  { float_ge "${DEFAULT_FALLBACK_RATE}" "0.05" || float_ge "${ROW_DROP_RATE}" "0.10"; }; then
  SEVERITY="warning"
  REASON="Fallback/drop threshold breached"
elif [[ "${TOTAL_EVENTS}" -ge 100 ]] &&
  float_ge "${PARSED_WITH_DROPS_RATE}" "0.02"; then
  SEVERITY="info"
  REASON="Parsed-with-drops trend above info threshold"
fi

PARSE_SUCCESS_PCT="$(float_percent "${PARSE_SUCCESS_RATE}")"
FALLBACK_PCT="$(float_percent "${DEFAULT_FALLBACK_RATE}")"
HARD_FAILURE_PCT="$(float_percent "${HARD_FAILURE_RATE}")"
ROW_DROP_PCT="$(float_percent "${ROW_DROP_RATE}")"
MISSING_PCT="$(float_percent "${MISSING_RATE}")"
DROPS_PCT="$(float_percent "${PARSED_WITH_DROPS_RATE}")"

SUMMARY="backup_provider_options health [${SEVERITY}] (${REASON})
window_end=${WINDOW_END}
total_events=${TOTAL_EVENTS}
parse_success_rate=${PARSE_SUCCESS_PCT}%
default_fallback_rate=${FALLBACK_PCT}%
hard_failure_events=${HARD_FAILURE_EVENTS}
hard_failure_rate=${HARD_FAILURE_PCT}%
row_drop_rate=${ROW_DROP_PCT}%
parsed_with_drops_rate=${DROPS_PCT}%
missing_rate=${MISSING_PCT}%"

echo "${SUMMARY}"

if [[ -n "${JSON_OUT}" ]]; then
  mkdir -p "$(dirname "${JSON_OUT}")"
  jq '.' <<< "${ROW}" > "${JSON_OUT}"
  echo "Wrote JSON metrics: ${JSON_OUT}"
fi

if [[ -n "${MARKDOWN_OUT}" ]]; then
  mkdir -p "$(dirname "${MARKDOWN_OUT}")"
  cat > "${MARKDOWN_OUT}" <<EOF
# Backup Provider Config Health Check

- Project: \`${PROJECT_ID}\`
- Dataset: \`${DATASET}\`
- Window End: \`${WINDOW_END}\`
- Severity: \`${SEVERITY}\`
- Reason: ${REASON}

## Metrics

- total_events: ${TOTAL_EVENTS}
- parse_success_rate: ${PARSE_SUCCESS_PCT}%
- default_fallback_rate: ${FALLBACK_PCT}%
- hard_failure_events: ${HARD_FAILURE_EVENTS}
- hard_failure_rate: ${HARD_FAILURE_PCT}%
- row_drop_rate: ${ROW_DROP_PCT}%
- parsed_with_drops_rate: ${DROPS_PCT}%
- missing_rate: ${MISSING_PCT}%
EOF
  echo "Wrote Markdown report: ${MARKDOWN_OUT}"
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry-run enabled; skipping webhook send."
else
  if [[ "${SEVERITY}" != "ok" && -n "${WEBHOOK_URL}" ]]; then
    PAYLOAD="$(jq -n \
      --arg text "${SUMMARY}" \
      '{text: $text}')"
    curl -fsS -X POST \
      -H 'Content-Type: application/json' \
      --data "${PAYLOAD}" \
      "${WEBHOOK_URL}" >/dev/null
    echo "Webhook notification sent."
  fi
fi

case "${SEVERITY}" in
  critical) exit 2 ;;
  warning) exit 1 ;;
  *) exit 0 ;;
esac
