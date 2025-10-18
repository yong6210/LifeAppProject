# Life App Data Retention & Disclosure Notes

This document summarizes how user data is handled to support privacy policy copy and store disclosures.

## Storage Locations

- **On-device (ISAR database):** Sessions, routines, settings, daily summaries, change logs, backup metadata. 운동 세션 중에만 수집한 위치 스냅샷도 함께 저장되며, 세션이 삭제되면 위치 데이터도 함께 제거됩니다.
- **Light Sync (Firestore):** Minimal profile (theme, presets) and per-device daily summaries. Data keys are namespaced by Firebase UID and device identifier. Retained only while the account exists.
- **User-managed backups:** Encrypted ISAR archives that the user explicitly exports to Google Drive/iCloud. Removal is under the user’s control.
- **Diagnostics (optional):** Crashlytics error reports and anonymized analytics are collected only when telemetry consent is granted in-app.

## Deletion Flows

1. **In-app account deletion** clears local storage, revokes encryption keys, removes Firestore settings/daily summaries, and attempts to delete the Firebase user record. The user is signed out afterwards.
2. **Manual backup removal** is the user’s responsibility; the app prompts users to delete uploaded backup files when off-boarding.
3. **Crash/analytics opt-out** immediately stops new event collection; existing reports age out per Firebase retention rules (~90 days).

## Platform Disclosures

- **iOS (App Store):** Data types listed under “Data Linked to You”: app usage (sessions/daily summaries), 운동 중 수집되는 위치 기록(Outdoor Workout Sessions), identifiers (deviceId), diagnostics (if consented). 모든 항목은 사용자 동의 시에만 활성화됩니다.
- **Google Play:** Data safety form should mark “Data deletion available” with link to in-app deletion flow. 위치 권한은 “야외 운동 거리/페이스 측정을 위한 용도”로 명시하고, exact alarm 등 다른 민감 권한과 동일하게 목적을 안내합니다.

## Exceptional Retention Cases

- Payment receipts remain with RevenueCat/App Store for financial reconciliation; the app does not store raw receipts.
- Support logs (if the user exports diagnostics) are temporary and user-controlled.

_Updated: 2025-10-03_
