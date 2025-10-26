# Life App Privacy Policy (Draft)

_Last updated: 2025-10-12_

## 1. Overview
Life App is an offline-first wellbeing timer. We minimise cloud storage to essentials the user opts into. This draft outlines data practices for legal/privacy review prior to publication.

## 2. Data Controller
- **Company:** Life App Studio (placeholder)
- **Contact:** privacy@lifeapp.example
- **Address:** 123 Wellness Road, Seoul, Republic of Korea (update with real address)

## 3. Data We Collect
### 3.1 Required to operate the service
- **Device identifier (dev-...)** – generated locally to distinguish uploads per device.
- **Timer sessions & routines** – stored locally only.
- **Settings / presets / daily summaries** – stored locally and optionally synced to Firestore for cross-device recovery.

### 3.2 Optional / user initiated
- **Encrypted full backups** – created only when the user exports them to Google Drive or iCloud; the file remains under the user’s cloud account.
- **Crash reports & analytics** – collected only if the user enables telemetry in-app. Providers: Firebase Analytics and Crashlytics.
- **Revenue events** – managed by RevenueCat to validate App Store / Play receipts. We do not store raw payment details.
- **Location data (outdoor workouts)** – collected at 30분 간격으로 야외 운동 세션이 진행되는 동안에만 거리·페이스 계산을 위해 사용하며, 세션이 종료되면 즉시 수집을 중단합니다.
- **Sleep sound analysis (opt-in)** – when the user enables Sleep mode’s sound insights we capture on-device audio snippets, amplitude samples, and derived noise events. Raw audio stays on the device; only summaries are stored locally. Uploads occur only if the user explicitly backs up the session.
- **Routine personalization metrics** – timer usage counts, focus duration, and habit tags remain on-device. We ask for explicit consent before syncing these summaries for cross-device personalization.

## 4. Purposes of Processing
- Provide timer, backup and sync functionality.
- Restore purchases across platforms via RevenueCat.
- Monitor stability and improve UX when telemetry is enabled.
- Provide 거리/페이스 기반 운동 통계와 위치 기반 루틴 추천(사용자가 야외 운동을 시작할 때 명시적으로 권한을 허용한 경우에 한함).
- Provide optional on-device routine suggestions based on usage patterns. We only upload aggregate scores if the user turns on “cloud sync for suggestions” in Settings.
- Provide optional sleep sound insights (snore/ambient event detection) when the user opts in, so they can understand rest quality trends.
- Respond to support requests (user-initiated log export only).

## 5. Legal Bases
- **Contractual necessity:** core timer features, account login.
- **User consent:** telemetry, optional backups, email support.
- **Legitimate interest:** fraud prevention via RevenueCat (pseudonymous identifiers), service security.

## 6. Data Retention
- Local data persists on the device until deleted by the user.
- Firestore light-sync documents are removed when the user deletes the account.
- Encrypted backups remain in the user’s cloud storage until the user deletes them.
- Sleep sound raw audio is purged automatically after 3 days (configurable in settings). Users can delete sooner from Settings ▸ 데이터 관리 ▸ 수면 사운드 기록.
- Crash/analytics logs follow Firebase standard retention (approx. 90 days) and are stopped immediately if consent is revoked.

## 7. User Rights
Users can:
- Access, update or delete synced data via the app.
- Export an encrypted backup at any time.
- Delete the account from Settings → Account & Subscription → Account Deletion.
- Toggle telemetry consent in Settings (planned UI toggle; currently telemetry is disabled by default).
- Enable or disable outdoor workout location tracking at any time from Settings ▸ Privacy.
- Choose between “on-device only” or “sync across devices” for routine suggestions. Disabling sync keeps personalization local while continuing to offer manual presets.
- Contact privacy@lifeapp.example for data subject requests.

## 8. Data Sharing
- **Firebase (Google LLC, USA/EU regions)** – Auth, Firestore, Analytics/Crashlytics (optional).
- **RevenueCat, Inc. (USA)** – Subscription validation.
- **Google Drive / Apple iCloud** – optional user-hosted backups.
We do not sell personal data or share with advertisers.

## 9. International Transfers
Firebase and RevenueCat may transfer data to the United States. Standard Contractual Clauses (SCCs) and service-level DPAs apply. Users can opt out by disabling sync and telemetry.

## 10. Security Measures
- AES-256-GCM encryption for full backups; keys stored in Keychain/Keystore.
- Sleep sound files use OS-provided secure storage (`NSFileProtectionCompleteUntilFirstUserAuthentication` on iOS, private app storage + AES-256 on Android). Summaries remain on-device unless the user backs them up.
- Foreground services and local notifications run with least privilege.
- Firebase security rules restrict access to authenticated user documents only.

## 11. Children’s Privacy
Life App is not directed to children under 13 (or local age of consent). If we learn we collected data improperly, we will purge it promptly.

## 12. Policy Updates
We will notify users in-app before material changes. Continued use after updates constitutes acceptance.

## 13. Contact
For privacy questions or to exercise rights, email privacy@lifeapp.example.

## 14. Regional Disclosures (United States & Korea)
- **United States** – We follow CPRA/CCPA principles. Personalized routines are opt-in; you may continue using standard timers without sharing personal data. Every personalization feature lists what is processed locally and what (if anything) syncs to the cloud.
- **Republic of Korea** – We comply with PIPA requirements. 선택형 기능(운동 위치, 수면 분석, 루틴 추천 동기화)은 언제든지 해지하거나 삭제할 수 있으며, 삭제 시 서버에 남아 있는 데이터는 즉시 파기됩니다.

---
_Next steps:_ Legal review, localised translations, integrate toggle surfaces for telemetry, update store listings with final URL.
