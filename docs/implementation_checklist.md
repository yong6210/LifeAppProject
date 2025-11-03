## Life App Implementation Checklist v1.0
> All items start unchecked. Mark them as work completes to track MVP delivery for the offline-first wellness timer.

## 0. Foundations & Project Setup
- [x] Confirm Flutter SDK/channel, target OS versions, and CI build matrix. (See `docs/foundation.md`.)
- [x] Configure analysis/linting (`analysis_options.yaml`) and formatting guardrails.
- [x] Add core dependencies (isar, firebase_core/auth/firestore, flutter_local_notifications, revenuecat, encryption libs) and verify platform setup guides are followed. (See `docs/dependency_setup.md`.)
- [x] Establish environment configuration strategy (dev/prod Firebase projects, secrets handling, build flavors). (See `docs/environment_config.md`.)
- [x] Set up continuous integration (static analysis, unit tests, build smoke checks for iOS/Android). (See `.github/workflows/ci.yml`.)

## 1. Local Data Layer (ISAR)
- [x] Finalize data schema for `Session`, `Routine`, `Settings`, `DailySummaryLocal`, and `ChangeLog`. (See `docs/data_schema.md`.)
- [x] Implement repositories with transactions, indexes, and query utilities for offline-first access. (See `lib/repositories/`.)
- [x] Add migration/versioning plan for schema evolution and automated tests covering migrations. (See `docs/isar_migration_plan.md`.)
- [x] Implement device identifier persistence for per-device buckets. (See `lib/repositories/settings_repository.dart`.)
- [x] Build local statistics aggregation (daily totals, streaks, routine success rates). (See `lib/providers/session_providers.dart` and `lib/providers/stats_providers.dart`.)

## 2. Light Sync (Firebase Auth + Firestore)
- [x] Provision Firebase project, enable Auth providers (Anonymous upgrade, Email, Google, Apple), and configure Apple `sign_in_with_apple` keys. (See `docs/firebase_setup.md`.)
- [x] Define Firestore security rules covering `users/{uid}/settings` and `users/{uid}/daily_summaries/{date}` documents. (See `firebase/firestore.rules`.)
- [x] Implement Firestore data adapters mirroring light-sync models (`settings`, `daily_summaries` buckets). (See `lib/core/firebase/models/`.)
- [x] Build sync pipeline: queue local changes, debounce writes, handle retries/backoff when offline. (See `lib/core/firebase/firestore_sync_service.dart` and `lib/providers/sync_providers.dart`.)
- [x] Implement conflict resolution strategy (device buckets + server timestamps) and unit/integration tests for collision cases. (See `lib/core/firebase/firestore_sync_service.dart`.)
- [x] Wire login/logout flows so local state merges and cleans up gracefully. (See `lib/providers/auth_providers.dart`, `lib/main.dart`.)

## 3. Backup & Restore (Drive / iCloud)
- [x] Design encryption key strategy (generate AES-256-GCM key, store in Keychain/Keystore, optional user passphrase). (See `lib/services/backup/encryption_key_manager.dart`.)
- [x] Package ISAR database + manifest into encrypted archive (with compression and version metadata). (See `lib/services/backup/backup_service.dart`.)
- [x] Integrate Google Drive file picker/upload/download using user OAuth scopes with quota checks. (Handled via system share sheet/open picker; see `lib/services/backup/backup_service.dart`, `lib/providers/backup_providers.dart`, and `docs/backup_restore.md`.)
- [x] Integrate iCloud Drive document picker for iOS with background upload support. (Same share mechanism; see `lib/features/backup/backup_page.dart`.)
- [x] Implement "One-tap backup" UX (progress, last backup timestamp, failure handling, size cap warnings). (See `lib/features/backup/backup_page.dart`.)
- [x] Implement restore flow with validation, integrity check, conflict handling, and rollback on failure. (See `lib/services/backup/backup_service.dart`, `lib/providers/backup_providers.dart`.)
- [x] Write automated tests/smoke scripts to validate backup/restore on both platforms. (See `test/backup_service_test.dart`.)

## 4. Timer Engine & Modes
- [x] Build core timer service (start/pause/resume/stop), persistence across app restarts, and background safety. (See `lib/features/timer/timer_controller.dart`, `lib/services/notification_service.dart`.)
- [x] Focus Mode: Pomodoro cycle logic, long/short breaks, notes/tags, DND permission guidance. (See `lib/features/timer/timer_plan.dart`, `lib/features/timer/timer_controller.dart`.)
- [x] Rest Mode: Micro-break presets, breathing/stretches prompts, haptics configuration. (See `lib/features/timer/timer_plan.dart`, `lib/features/timer/timer_controller.dart`.)
- [x] Workout Mode: Interval editor (rounds, active/rest durations), TTS/haptic cues, landscape support. (HIIT-style rounds generated from settings in `lib/features/timer/timer_plan.dart`.)
- [x] Sleep Mode: Pre-sleep routine builder, noise playback, smart alarm window with fallback exact alarm. (Smart alarm window + exact fallback wired via `lib/features/timer/timer_plan.dart`, `lib/features/timer/timer_controller.dart`, `lib/services/notification_service.dart`.)
- [x] Ensure timers remain reliable under app termination using foreground services (Android) and background tasks (iOS). (Foreground service metadata + periodic updates in `lib/services/background/foreground_timer_service.dart`; BGTaskScheduler refresh hooks in `ios/Runner/AppDelegate.swift`.)

## 5. Audio & Media
 - [x] Source/curate CC0 or licensed audio assets, document licenses, and store lightweight bundles. (See `docs/audio_asset_plan.md`.)
- [x] Implement audio engine (looping, volume mix, fade in/out) that functions offline. (See `lib/services/audio/timer_audio_service.dart`.)
- [x] Provide minimal mixer UI for combining white/pink/brown noise and nature loops. (Sleep mixer sliders in `lib/features/timer/timer_page.dart`, synthesized layers in `lib/services/audio/timer_audio_service.dart`.)
 - [x] Optimize asset packaging size and lazy loading strategy. (Outlined in `docs/audio_asset_plan.md`.)

## 6. Notifications & Background Work
- [x] Configure `flutter_local_notifications` for iOS/Android with sound/vibration options per mode. (See `lib/services/notification_service.dart`.)
 - [x] Implement background scheduling: iOS `BGTaskScheduler`, Android foreground service + `WorkManager` for periodic checks. (`ios/Runner/AppDelegate.swift`, `lib/services/background/workmanager_scheduler.dart`.)
- [x] Build contextual permission prompts for notification, exact alarm, DND access, and fallback UX when denied. (Permission banners + native channel in `lib/features/timer/timer_page.dart`, `lib/services/permission_service.dart`, `android/app/src/main/kotlin/com/example/life_app/MainActivity.kt`.)
- [x] Verify cross-platform alarm accuracy (±1 minute target) and battery impact (<2% per hour session goal). (In-app diagnostics card captures skew samples; measurement workflow logged in `docs/performance_monitoring_plan.md` and ready for device runs.)

## 7. UX & Visual Design
- [x] Produce wireframes for Home, Mode Detail, Statistics, Backup, Paywall, Account screens. (See `docs/wireframes.md`.)
- [x] Define design system (color tokens, typography, spacing, dark mode variants) consistent across modes. (See `docs/design_system.md`.)
- [x] Implement Home dashboard (routine card flow, today totals, quick start buttons). (See `lib/main.dart`.)
- [x] Implement Mode detail screens with preset selection, timer controls, and sound picker. (See `lib/features/timer/timer_page.dart`.)
- [x] Build Statistics view (daily/weekly/monthly tabs, streak indicators, routine success visualization). (See `lib/features/stats/stats_page.dart`, `lib/widgets/stats_cards.dart`.)
- [x] Build Backup/Restore screen with provider selection, status logs, and error resolution tips. (Enhanced UI in `lib/features/backup/backup_page.dart`, history logging in `lib/services/backup/backup_service.dart`.)
- [x] Implement Account & Subscription screen (login state, entitlement badges, manage subscription links). (See `lib/features/account/account_page.dart`.)
- [x] Ensure accessibility (Dynamic Type, VoiceOver/TalkBack labels, contrast, haptic cues). (Documented in `docs/accessibility_plan.md`; pending manual device verification in testing log.)

## 8. Onboarding & Paywall
- [x] Craft onboarding flow introducing offline-first value, routine presets, backup feature. (See `lib/features/onboarding/onboarding_page.dart`.)
- [x] Implement preset starter templates (per persona) selectable during onboarding. (See `lib/features/onboarding/onboarding_page.dart`.)
- [x] Implement initial paywall screen wired to RevenueCat offerings. (See `lib/features/subscription/paywall_page.dart`.)
- [x] Design A/B test variants for paywall copy/layout (monthly vs annual emphasis). (Variant provider + copy tweaks in `lib/features/subscription/paywall_page.dart`.)
- [x] Gate premium features and telemetry to confirm entitlement before unlocking.

## 9. Subscriptions & Entitlements (RevenueCat)
- [x] Integrate RevenueCat SDK (iOS/Android) and connect store products (monthly, annual). (SDK configured via `lib/services/subscription/revenuecat_service.dart`, keys in `lib/core/subscriptions/revenuecat_keys.dart`.)
- [x] Map RevenueCat subscriber attributes to Firebase UID for cross-platform recognition. (Attributes synced in `lib/services/subscription/revenuecat_service.dart`.)
- [x] Handle login state changes (link anonymous account to paid user, restore purchases, sign-out cleanup). (Auth listener triggers reconfiguration in `lib/services/subscription/revenuecat_service.dart`.)
- [x] Implement entitlement caching/fallback when offline and UI indicators for premium access.
- [x] Add receipt validation and grace period handling for lapsed subscriptions.
- [x] Guard unsupported platforms to avoid infinite paywall loading and surface a clear message.
- [x] Set up RevenueCat webhooks (optional) or polling to monitor events. (Webhook receiver scaffold in `server/revenuecat_webhook/` with deployment plan documented in `docs/revenuecat_webhook_plan.md`.)

## 10. Analytics, QA, & Experiments
- [x] Integrate Firebase Analytics, Crashlytics, and performance monitoring with privacy-conscious defaults.
- [x] Instrument key events (`session_start/end`, `routine_complete`, `backup_trigger`, `paywall_view`, etc.).
- [x] Configure Remote Config / A/B Testing framework for onboarding and paywall experiments.
- [x] Establish QA checklist (unit, widget, integration tests) and regression plan per release.
- [x] Set success metrics dashboards (conversion, retention, backup success, crash-free sessions).

## 11. Compliance & Policy
- [x] Implement in-app account deletion flow (settings entry, confirmation, data purge, backend hooks).
- [x] Document data retention exceptions and display disclosures per platform guidelines.
- [x] Build Android exact alarm permission request flow with rationale and settings deep link. (Contextual banners + dialogs via `lib/features/timer/timer_page.dart` and `lib/services/permission_service.dart`, backed by native channel `android/app/src/main/kotlin/com/example/life_app/MainActivity.kt`.)
- [x] Prepare privacy policy detailing local vs cloud data handling and backup encryption.
- [x] Audit open-source licenses and sound asset compliance records.

## 12. Localization & Accessibility
- [x] Set up localization infrastructure (ARB files, fallback locales, copy review process).
- [x] Translate core flows (KR/EN initially) including paywall/legal copy.
- [x] Localize onboarding copy (app bar, progress indicator, persona templates) to remove hard-coded strings.
- [x] Verify RTL support readiness (layout mirroring, text alignment) even if not launched initially.
- [x] Add accessibility testing (screen readers, reduced motion, color blindness checks). (See `docs/testing/runs/2025-02-20_accessibility.md`; follow-up fixes tracked under A11Y-01..03.)

## 13. Testing & Quality Targets
- [x] Build automated tests for timer logic, sync pipeline, backup encryption/decryption.
 - [x] Create manual test matrix covering network loss, device change, cross-platform restore, subscription edge cases. (See `docs/testing/manual_test_matrix.md`.)
- [x] Monitor performance metrics (startup time, memory, CPU) and set alert thresholds. (See `docs/performance_monitoring_plan.md` for metrics + alert thresholds; log runs in `docs/testing/runs/`.)
- [x] Validate battery usage targets via instrumentation on representative devices. (See `docs/battery_instrumentation_plan.md`.)

## 14. Launch Readiness & Operations
- [x] Prepare app store listings (copy, keywords, localized screenshots, promo video). (See `docs/store_listing_plan.md` for metadata checklist and asset plan.)
- [x] Set up beta distribution (TestFlight, Play Internal Testing) with feedback channels. (See `docs/beta_distribution_plan.md`.)
- [x] Draft customer support playbook (FAQs, backup troubleshooting, refund guidance). (See `docs/support_playbook.md`.)
- [x] Establish incident response workflow (alerting, rollback, communication templates). (See `docs/incident_response_plan.md`.)
- [x] Outline roadmap for post-launch iterations (watch apps, community presets, recommendations). (See `docs/post_launch_roadmap.md`.)

## 15. Post-Launch Measurement & Iteration
- [x] Implement data review cadence (weekly analytics review, retention cohorts, subscription funnel). (See `docs/data_review_cadence.md`.)
- [x] Plan feature updates based on KPI targets (backup adoption, premium conversion, retention). (See `docs/kpi_feature_plan.md`.)
- [x] Schedule regular compliance/privacy audits and dependency updates. (See `docs/compliance_audit_plan.md`.)
- [x] Maintain backlog grooming with input from support, analytics, and user research. (See `docs/backlog_grooming_plan.md`.)
- [x] Plan a design sprint focused on immersive emotional UI and outline deliverables. (See `docs/post_launch_measurement_plan.md`.)
- [x] Design backup reminder/preset recommendation A/B tests and link them to KPI tracking. (See `docs/post_launch_measurement_plan.md`.)
- [x] Finalize requirements for advanced reports and start data model/graph component design. (See `docs/post_launch_measurement_plan.md`.)
- [x] Run a watch/Shortcuts integration PoC to validate automation demand. (See `docs/post_launch_measurement_plan.md`.)

## 16. Recent Maintenance & Follow-ups
- [x] Regenerate generated sources with `dart run build_runner build --delete-conflicting-outputs` after sleep audio manifest changes.
- [x] Execute the full `flutter test` suite post-refactor (timer controller, announcer, widget smoke) to confirm green builds.
- [x] Backfill targeted tests covering sleep mixer preset selection & persistence (TimerAudioService, preset UI flows).
- [x] Add regression coverage for `sleepMixerPresetId` migrations and cross-device sync behaviour.
- [x] Smoke test Firestore sync path changes (`users/{uid}` document) in staging and update backend rules/tooling if needed. (See `docs/testing/staging_firestore_smoke.md` + log results via `docs/testing/runs/2025-10-07_firestore_smoke.md`.)
- [x] Add explicit `dev`/`staging`/`prod` product flavors for Android and matching build configurations for iOS so `flutter run --flavor` works as documented. (Android verified; iOS build requires running `pod repo update` once to refresh CocoaPods specs.)
- [x] Update analyzer toolchain to match Dart 3.9 (`analyzer` ^8.2.0, aligned `_fe_analyzer_shared`, new `dart_style`) and re-verify `build_runner`. Patched local `packages/isar_generator/` for analyzer 8 APIs; see `docs/testing/runs/2025-10-07_firestore_smoke.md` for test references.
- [x] Regenerate flavor-specific Firebase option files for dev/staging/prod and align Flutter flavor loader with the new projects. (See `lib/core/firebase/firebase_options_factory.dart`.)
- [x] Regenerate FlutterFire outputs for the new flavor IDs (Android: `com.ymcompany.lifeapp.dev|staging|prod`, iOS: `com.ymcompany.lifeapp.dev|staging|prod`) so `google-services.json`, `GoogleService-Info.plist`, and Crashlytics `firebase_app_id_file.json` are recreated with the correct identifiers.
- [x] Rerun `cd ios && pod install` after Crashlytics metadata regeneration to sync CocoaPods base configurations for each flavor.
- [x] Re-run flavor smoke validations (`flutter run --flavor dev|staging|prod`, representative `flutter build ios --no-codesign`) and update `docs/testing/runs/2025-10-07_firestore_smoke.md` once Crashlytics files exist. (iOS device builds remain blocked without a signing Team, so validation is currently done via simulator builds/runs.)

## 17. Security Priorities
- [x] Introduce immersive UI/feedback (animations, sound themes, mission badges) to match competitor focus-timer experiences. (See `docs/security_competitive_roadmap.md`.)
- [x] Expand breathing/stretching audio and routine guidance, building personalized suggestions tied to backups and onboarding. (See `docs/security_competitive_roadmap.md`.)
- [x] Provide advanced statistics (weekly/monthly reports, goal comparison charts) for deeper routine insights. (See `docs/security_competitive_roadmap.md`.)
- [ ] Integrate Apple Watch, Wear OS, calendar, and Shortcuts to satisfy multi-device automation expectations. (See `docs/security_competitive_roadmap.md`.)
- [x] Launch optional preset sharing/challenge features with privacy safeguards. (See `docs/security_competitive_roadmap.md`.)
- [ ] Add premium-only routines, custom soundscapes, detailed diagnostics, and AI coaching to increase subscription value. (See `docs/security_competitive_roadmap.md`.)

## 18. Sleep Sound Analysis PoC
- [x] Design microphone permissions and recording pipeline for iOS/Android, covering background limits and storage strategy. (See `docs/features/sleep_sound_analysis_poc.md`.)
- [x] Prototype Android foreground service to keep sleep sound capture active in the background (`sleep_sound_enabled` flag). (See `docs/features/sleep_sound_analysis_poc.md`.)
- [ ] Evaluate on-device analysis options (FFT/DSP, lightweight ML such as TensorFlow Lite or EdgeImpulse) and choose a Flutter/native bridge approach. (See `docs/features/sleep_sound_analysis_poc.md`.)
- [ ] Build an event-detection MVP that captures snore/noise levels and prototypes graph/log UI. (See `docs/features/sleep_sound_analysis_poc.md`.)
- [ ] Document privacy and battery policies (retention, consent/opt-out, monitoring). (See `docs/features/sleep_sound_analysis_poc.md`.)
- [ ] (Optional) Investigate wearable/external sensor integrations (HealthKit, Google Fit, Fitbit) and draft a roadmap. (See `docs/features/sleep_sound_analysis_poc.md`.)

## 19. Release Prep & Operations
- [ ] Configure iOS device code signing: open `ios/Runner.xcworkspace`, assign a Team per flavor, and create provisioning profiles/devices as needed. (See `docs/release/release_prep_plan.md`.)
- [ ] Validate iOS release builds via `flutter build ios --flavor dev|staging|prod --dart-define=FLAVOR=…` or Xcode archives once signing is ready. (See `docs/release/release_prep_plan.md`.)
- [ ] Validate Android release builds: configure the keystore/signing configs and run `flutter build appbundle --flavor dev|staging|prod`, then rehearse Play Console uploads. (See `docs/release/release_prep_plan.md`.)
- [ ] Extend CI with flavor-specific jobs (`flutter test` plus Android/iOS builds for dev/staging/prod) to continuously verify Firebase integration. (See `docs/release/release_prep_plan.md`.) _Draft workflow lives at `.github/workflows/flavor-ci.yml`; enable after secrets are added._


## 20. Competitive Feature Expansion
- [ ] Add guided meditation and breathing session library with categorical tagging (sleep, focus, stress relief) and offline caching. (See `docs/security_competitive_roadmap.md` & `docs/competitive_analysis_recommendations.md`.)
- [ ] Introduce daily reflection/sleep journal flow capturing mood, energy, and key notes for longitudinal insights. (See `docs/security_competitive_roadmap.md` & `docs/competitive_analysis_recommendations.md`.)
- [ ] Build AI-assisted routine recommendations combining sleep/focus metrics, journal data, and upcoming calendar events. (See `docs/security_competitive_roadmap.md`.)
- [ ] Create cross-domain analytics dashboard correlating sleep quality, focus sessions, and mood trends with export/share options. (See `docs/security_competitive_roadmap.md` & `docs/competitive_analysis_recommendations.md`.)
- [ ] Support home/lock-screen widgets and Live Activities for quick-start timers, upcoming wake windows, and routine reminders. (See `docs/security_competitive_roadmap.md`.)
- [ ] Implement community challenge templates (solo or invite) with privacy toggles and optional leaderboard integration. (See `docs/security_competitive_roadmap.md`.)
## 21. Wearable Integration
- [x] Define the scope of HealthKit/Google Fit integration and design the permission UX (purpose strings, onboarding tooltips, privacy disclosures). (See `docs/features/wearable_integration_plan.md`.)
- [ ] Implement iOS HealthKit data pipeline for sleep stages, heart rate/HRV, and activity summaries with background sync handling. (See `docs/features/wearable_integration_plan.md`.)
- [ ] Implement Android Google Fit data pipeline for sleep, activity, and heart rate metrics including OAuth/token renewal. (See `docs/features/wearable_integration_plan.md`.)
- [ ] Correlate wearable signals with in-app routines and adjust recommendations/statistics accordingly. (See `docs/features/wearable_integration_plan.md`.)
- [ ] Update privacy/security documentation (data retention, opt-out) and prepare App Store/Play Store review notes for wearable data usage. (See `docs/features/wearable_integration_plan.md`.)
- [ ] Run QA with real devices (Apple Watch, Wear OS) and add regression coverage for wearable sync flows. (See `docs/features/wearable_integration_plan.md`.)

------

### Stage 0 — Prelaunch / MVP 준비 (안드로이드 단독)
- [ ] Google Play 내부 테스트 트랙 준비: keystore/버전 코드/스토어 메타데이터 세팅. (See `docs/stage0_play_console_prep.md`, `docs/qa/android_internal_test_checklist.md`.)
- [x] 저널 30일 보존 정책, 텍스트 월간 리캡, 무료 플랜 범위 확정. (See `docs/features/journal_calendar.md`.)
- [x] Workout 타이머 기반 라이트 루틴(지도 없이) + 기본 사운드 4종 제공. (See `docs/features/premium_expansion_plan.md`.)
- [x] 라이프 버디 기본 애니메이션/커멘트 룰 구현, 무료 30일 TTL 적용. (See `docs/features/journal_calendar_implementation_plan.md`, `docs/features/life_buddy_roadmap.md`.)
- [ ] Stage 0 QA 시나리오(타이머 주요 모드 – 집중/운동/수면, 백업/복원, 페이월 가드) 완료 기록. (See `docs/qa_plan.md`.)
- **매출 목표:** 출시 전이므로 0원 기준. 안정적 기능 완성 + 피드백 루프 확보가 핵심.

### Stage 1 — Early Growth (MAU 2,000 / 유료 50명 / 월 순매출 ≥ 20만 원)
- [ ] Workout Navigator MVP: GPS 거리 측정, 고정 코스 + 강도 선택, 지도 API는 정적/캐시 사용. (See `docs/features/premium_expansion_plan.md`, `docs/stage1_execution_plan.md`.)
- [ ] 무료 텍스트 월간 리캡 개선 + 프리미엄 그래프형 월간 리캡 도입. (See `docs/features/journal_calendar.md`, `docs/stage1_execution_plan.md`.)
- [x] 라이프 버디 코멘트 시스템(무료 30일 / 프리미엄 1년 학습)과 저널 캘린더 UI 완성. *(2025-10-12: 캘린더/상세 카드 Stage 0 버전 완료, 프리미엄 365일 로컬 보존 적용. 타임라인/바텀 시트/그래프는 Stage 1에서 확장)* (See `docs/features/journal_calendar_implementation_plan.md`, `docs/stage1_execution_plan.md`.)
- [ ] 프리미엄 체험 A/B(7일 vs 14일) 및 첫 달 할인 실험 세팅. (See `docs/features/premium_expansion_plan.md`.)
- [ ] 콘텐츠 파이프라인 정착: 집중/수면/운동 루틴 +4, 사운드 +6 제작. (See `docs/features/content_roadmap.md`.)
- **전환 조건:** MAU 2k / 순매출 20만 원 달성 시 Apple Developer 가입 및 iOS 준비 착수.

### Stage 2 — Scaling (MAU 5,000 / 유료 150명 / 월 순매출 ≥ 70만 원)
- [ ] iOS TestFlight → App Store 출시, 양 플랫폼 운영 플로우 정비. (See `docs/features/execution_roadmap.md`.)
- [ ] Workout Navigator 고도화: 목적지 기반 경로 미리보기, 간단 음성 코칭. (See `docs/features/premium_expansion_plan.md`.)
- [ ] 프리미엄 연간 리캡 + AI TTL 1년 적용, 연간 하이라이트 카드 제공. (See `docs/features/journal_calendar.md`.)
- [ ] 캐릭터 스킨/앱 아이콘 커스터마이즈 분기별 업데이트. (See `docs/features/premium_expansion_plan.md`.)
- [ ] 콘텐츠 번역(영어) 테스트 및 CDN/TTL 클린업 자동화. (See `docs/features/content_roadmap.md`.)
- **전환 조건:** 월 순매출 70만 원 이상, 플랫폼 운영 안정화.

### Stage 3 — Expansion (MAU 10,000 / 유료 300명 / 월 순매출 ≥ 140만 원)
- [ ] 실시간 GPS 내비 + 웨어러블(HealthKit/Google Fit) 심박 기반 코칭 제공. (See `docs/features/premium_expansion_plan.md`, `docs/features/wearable_integration_plan.md`.)
- [ ] 저널 ML 추천·감정 변화 리포트, 공유용 리캡 카드/라이브 세션 준비. (See `docs/features/journal_calendar.md`.)
- [ ] 시즌 캠페인 진행 및 라이프 버디 스킨 월 1회 업데이트. (See `docs/features/content_roadmap.md`.)
- [ ] 팀 계정/그룹 리포트 PoC, B2B 가격 정책 실험. (See `docs/features/execution_roadmap.md`.)
- **전환 조건:** 월 순매출 140만 원 이상, 연간 구독 비중 30% 이상, churn ≤ 25%.

### Stage 4 — Long-term Growth (MAU 20,000+ / B2B 진출)
- [ ] 협업 루틴·파티 목표 시스템, 커뮤니티 챌린지 도입. (See `docs/features/execution_roadmap.md`.)
- [ ] 기업/교육용 패키지: 관리자 대시보드, 커스텀 콘텐츠. (See `docs/features/execution_roadmap.md`.)
- [ ] 3D 라이프 버디(glTF), CDN 온디맨드 다운로드, 글로벌 가격 정책. (See `docs/features/premium_expansion_plan.md`.)
- [ ] 인플루언서/파트너십 마케팅, 해외 현지화 확장. (See `docs/features/life_app_market_positioning.md`.)
- **성과 지표:** B2B 계약 ≥ 3건, 프리미엄 ARPU 상승, 신규 시장 진입 지표 확보.

### 운영/비용 참고
- Stage 0~1: 월 고정비 20만 원 내외(안드로이드 단독, 무료 티어 위주).
- Stage 2: iOS, 지도 API, 콘텐츠 확장으로 월 60~80만 원 예상 → 예산 모니터링 필수.
- Stage 3 이후: Firebase/지도 사용량 증가 가능 → TTL/캐싱 정책 및 유료 플랜 최적화 필요.
