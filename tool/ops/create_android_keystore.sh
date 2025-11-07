#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   tool/ops/create_android_keystore.sh \
#     --alias life_app_release \
#     --keystore android/keystore/life_app_release.keystore
#
# The script prompts for passwords when not supplied via environment variables.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANDROID_DIR="${ROOT_DIR}/android"
KEYSTORE_DIR="${ANDROID_DIR}/keystore"
KEY_PROPERTIES="${ANDROID_DIR}/key.properties"

ALIAS="${ANDROID_KEY_ALIAS:-}"
KEYSTORE_PATH=""
KEYSTORE_PASSWORD="${ANDROID_KEYSTORE_PASSWORD:-}"
KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --alias)
      ALIAS="$2"
      shift 2
      ;;
    --keystore)
      KEYSTORE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${ALIAS}" ]]; then
  read -r -p "Key alias [life_app_release]: " ALIAS
  ALIAS="${ALIAS:-life_app_release}"
fi

if [[ -z "${KEYSTORE_PATH}" ]]; then
  KEYSTORE_PATH="${KEYSTORE_DIR}/${ALIAS}.keystore"
fi

mkdir -p "${KEYSTORE_DIR}"

if [[ -z "${KEYSTORE_PASSWORD}" ]]; then
  read -r -s -p "Keystore password: " KEYSTORE_PASSWORD
  echo
  read -r -s -p "Confirm keystore password: " KEYSTORE_PASSWORD_CONFIRM
  echo
  if [[ "${KEYSTORE_PASSWORD}" != "${KEYSTORE_PASSWORD_CONFIRM}" ]]; then
    echo "Passwords do not match." >&2
    exit 1
  fi
fi

if [[ -z "${KEY_PASSWORD}" ]]; then
  read -r -s -p "Key password (leave blank to reuse keystore password): " KEY_PASSWORD
  echo
  if [[ -z "${KEY_PASSWORD}" ]]; then
    KEY_PASSWORD="${KEYSTORE_PASSWORD}"
  fi
fi

echo "Generating keystore at ${KEYSTORE_PATH} ..."
keytool -genkeypair \
  -alias "${ALIAS}" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650 \
  -keystore "${KEYSTORE_PATH}" \
  -storepass "${KEYSTORE_PASSWORD}" \
  -keypass "${KEY_PASSWORD}" \
  -dname "CN=Life App, OU=Engineering, O=Life App, L=Seoul, S=Seoul, C=KR"

cat > "${KEY_PROPERTIES}" <<EOF
storeFile=../keystore/$(basename "${KEYSTORE_PATH}")
storePassword=${KEYSTORE_PASSWORD}
keyAlias=${ALIAS}
keyPassword=${KEY_PASSWORD}
EOF

chmod 600 "${KEY_PROPERTIES}"

echo "Keystore and key.properties created."
echo "Remember to add the passwords to your secrets manager and keep ${KEYSTORE_PATH} backed up securely."
