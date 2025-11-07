#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE="${ROOT_DIR}/ios/Runner.xcworkspace"

if [[ ! -d "${ROOT_DIR}/ios" ]]; then
  echo "[error] ios directory not found. Run from repository root." >&2
  exit 1
fi

if [[ ! -d "${WORKSPACE}" ]]; then
  echo "[error] Xcode workspace not generated. Run 'flutter precache' and 'flutter build ios' first." >&2
  exit 1
fi

printf "Flavor,Configuration,DevelopmentTeam\n"

for flavor in dev staging prod; do
  scheme="${flavor}"
  configuration="Release-${flavor}"
  if [[ ! -f "${ROOT_DIR}/ios/Runner.xcodeproj/xcshareddata/xcschemes/${scheme}.xcscheme" ]]; then
    echo "[warn] Scheme ${scheme} not found; skipping." >&2
    continue
  fi
  team_id=$(xcodebuild \
    -workspace "${WORKSPACE}" \
    -scheme "${scheme}" \
    -configuration "${configuration}" \
    -showBuildSettings 2>/dev/null \
    | rg "DEVELOPMENT_TEAM" \
    | head -n 1 \
    | awk -F '=' '{print $2}' \
    | tr -d '[:space:]')

  if [[ -z "${team_id}" ]]; then
    team_id="<not-set>"
  fi

  printf "%s,%s,%s\n" "${flavor}" "${configuration}" "${team_id}"
done
