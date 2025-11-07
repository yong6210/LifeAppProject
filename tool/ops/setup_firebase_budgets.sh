#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tool/ops/setup_firebase_budgets.sh <gcp-project-id> <billing-account-id> <budget-amount-usd>
#
# Example:
#   ./tool/ops/setup_firebase_budgets.sh life-app-prod-1234 012345-6789AB-CDEF01 200
#
# Requirements:
#   - gcloud CLI authenticated with billing admin permissions.
#   - `billingbudgets.googleapis.com` API enabled on the target billing account.
#   - jq installed (optional; used for pretty-printing responses if available).

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <gcp-project-id> <billing-account-id> <budget-amount-usd>" >&2
  exit 1
fi

PROJECT_ID="$1"
BILLING_ACCOUNT="$2"
BUDGET_AMOUNT="$3"
BUDGET_DISPLAY_NAME="${PROJECT_ID}-monthly-budget"

echo "Creating/Updating budget '${BUDGET_DISPLAY_NAME}' for project '${PROJECT_ID}' (billing account ${BILLING_ACCOUNT}) with threshold \$${BUDGET_AMOUNT}"

PAYLOAD=$(cat <<EOF
{
  "budget": {
    "name": "",
    "displayName": "${BUDGET_DISPLAY_NAME}",
    "budgetFilter": {
      "projects": ["projects/${PROJECT_ID}"]
    },
    "amount": {
      "specifiedAmount": {
        "currencyCode": "USD",
        "units": "${BUDGET_AMOUNT}"
      }
    },
    "thresholdRules": [
      { "thresholdPercent": 0.5 },
      { "thresholdPercent": 0.75 },
      { "thresholdPercent": 0.9 },
      { "thresholdPercent": 1.0 }
    ],
    "allUpdatesRule": {
      "pubsubTopic": "",
      "schemaVersion": "1.0",
      "monitoringNotificationChannels": []
    }
  }
}
EOF
)

RESPONSE=$(gcloud beta billing budgets create \
  --billing-account="${BILLING_ACCOUNT}" \
  --data="${PAYLOAD}" 2>&1) || {
    if grep -q "already exists" <<< "${RESPONSE}"; then
      echo "Budget exists. Updating..."
      BUDGET_NAME=$(gcloud beta billing budgets list \
        --billing-account="${BILLING_ACCOUNT}" \
        --filter="displayName=${BUDGET_DISPLAY_NAME}" \
        --format="value(name)")

      if [[ -z "${BUDGET_NAME}" ]]; then
        echo "Could not find existing budget named ${BUDGET_DISPLAY_NAME}" >&2
        exit 1
      fi

      gcloud beta billing budgets update "${BUDGET_NAME}" \
        --billing-account="${BILLING_ACCOUNT}" \
        --data="${PAYLOAD}"
    else
      echo "${RESPONSE}" >&2
      exit 1
    fi
  }

if command -v jq >/dev/null 2>&1; then
  jq <<< "${PAYLOAD}" || true
else
  echo "${PAYLOAD}"
fi

echo "Budget configuration applied. Configure notifications (Pub/Sub or monitoring channels) via GCP console if required."
