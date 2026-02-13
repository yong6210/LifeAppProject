# Release Readiness

This document consolidates the release checklist, flavor configuration, and CI
expectations for Life App.

## Checklist
- [x] Confirm bundle IDs and app names for dev/staging/prod across Android, iOS, and macOS
- [x] Wire iOS code signing for dev/staging/prod (certs, profiles, entitlements)
- [x] Wire macOS code signing for dev/staging/prod (certs, profiles, entitlements)
- [x] Confirm Android release keystore and update `android/key.properties`
- [x] Configure GitHub Actions CI for analyze/test + flavor builds
- [x] Verify flavor builds exist for Android, iOS, and macOS
- [x] Publish 2026 Q1 core-tab UI redesign documentation
- [x] Publish unified execution audit + master checklist docs
- [x] Generate Stitch-Figma-Flutter gap report (`docs/reports/stitch_figma_flutter_gap_report_2026-02-13.md`)
- [x] Run full functional regression suite (`docs/ui_qa_run_casual_2026-02-13.md`)
- [ ] Complete `docs/ui_qa_checklist_casual_2026q1.md` on target devices
- [ ] Attach QA evidence (screenshots + pass/fail log) to release ticket

## UI Redesign Gate (2026 Q1)
- Design doc: `docs/ui_redesign_casual_2026q1.md`
- Execution audit: `docs/execution_status_gap_audit_2026-02-13.md`
- Master checklist: `docs/master_execution_checklist_2026q1.md`
- QA checklist: `docs/ui_qa_checklist_casual_2026q1.md`
- Latest run report: `docs/ui_qa_run_casual_2026-02-13.md`
- Gap report: `docs/reports/stitch_figma_flutter_gap_report_2026-02-13.md`
- Risk register source: `docs/notion/risk_register_db_2026q1.csv`
- Minimum validation command:
  - `flutter analyze lib/main.dart lib/features/home/casual_home_dashboard.dart lib/features/more/more_page.dart lib/features/account/account_page.dart lib/features/subscription/paywall_page.dart lib/features/timer/timer_page.dart lib/features/timer/timer_controller.dart`
- Widget regression commands:
  - `powershell -ExecutionPolicy Bypass -File tool/ops/check_screen_ownership.ps1`
  - `flutter test test/features/home/casual_home_dashboard_test.dart`
  - `flutter test test/features/more/more_page_test.dart`
  - `flutter test test/features/subscription/paywall_page_widget_test.dart`
  - `flutter test test/providers/paywall_experiment_provider_test.dart`
  - `flutter test test/timer/timer_controller_test.dart`
- KPI/Experiment gate:
  - Verify remote config keys exist in `remote_config/app`:
    - `paywall_variant` (`focus_value|backup_security|coach_momentum`)
    - `paywall_experiment_id`
    - `paywall_annual_emphasis` (`true|false`)
  - Recommended automation:
    - `tool/ops/set_remote_config_app.ps1`
    - `docs/ops/growth_operations_playbook.md`
  - Verify KPI events in GA4 debug view:
    - `kpi_paywall_view` includes `experiment_id`, `annual_emphasis`
    - `kpi_guided_exit` appears on guided reset/drop-off paths
- Windows note:
  - If build fails with `nuget.exe not found` (flutter_tts plugin), install NuGet
    CLI and add it to `PATH` before Windows build verification.
  - Helper script:
    - `powershell -ExecutionPolicy Bypass -File tool/ops/check_windows_nuget.ps1 -InstallIfMissing`
  - Current status:
    - `flutter build windows` PASS (user host verification complete).
    - `flutter run -d windows` PASS (runtime launch smoke complete).

## Release Gate Finalization (2026-02-13)
Gate 정책은 아래 4개 중 하나라도 미충족이면 `BLOCKED`로 간주한다.

| Gate | Current | Block Condition | Evidence |
| --- | --- | --- | --- |
| Static + Widget regression | PASS | `flutter analyze` 또는 회귀 테스트 1개 이상 실패 | `docs/ui_qa_run_casual_2026-02-13.md` |
| Screen ownership guardrail | PASS | legacy/figma import 위반 1건 이상 | `tool/ops/check_screen_ownership.ps1` |
| Stitch-Figma-Flutter gap visibility | PASS | 최신 날짜 갭 리포트 부재 | `docs/reports/stitch_figma_flutter_gap_report_2026-02-13.md` |
| Manual QA + evidence package | BLOCKED | 실기기 체크리스트 미완료 또는 증빙 미첨부 | `docs/ui_qa_checklist_casual_2026q1.md`, release ticket |

릴리즈 승인 조건:
1. `BLOCKED` gate가 0건일 것
2. `docs/notion/risk_register_db_2026q1.csv`의 `High` severity `Open` 항목에 대해 완화 계획/오너/검토일이 모두 채워져 있을 것
3. 릴리즈 티켓에 수동 QA 증빙 링크(스크린샷/영상/로그)가 첨부될 것

## Flavor Matrix
Android:
- `dev`: `com.ymcompany.lifeapp.dev`
- `staging`: `com.ymcompany.lifeapp.staging`
- `prod`: `com.ymcompany.lifeapp`

iOS:
- Schemes: `dev`, `staging`, `prod` (`ios/Runner.xcodeproj/xcshareddata/xcschemes/`)
- Configs: `Release-dev`, `Release-staging`, `Release-prod`

macOS:
- Config directories under `macos/Runner/Configs/` (`dev`, `staging`, `prod`)
- App info overrides in `AppInfo-<flavor>.xcconfig`

`FLAVOR` is injected via `--dart-define=FLAVOR=<flavor>` and used by
`lib/core/firebase/firebase_options_factory.dart` to select Firebase options.

## Build Commands
Android:
```sh
flutter build apk --flavor dev --dart-define=FLAVOR=dev
flutter build apk --flavor staging --dart-define=FLAVOR=staging
flutter build apk --flavor prod --dart-define=FLAVOR=prod
```

iOS (no codesign, simulator):
```sh
flutter build ios --simulator --no-codesign --flavor dev --dart-define=FLAVOR=dev
flutter build ios --simulator --no-codesign --flavor staging --dart-define=FLAVOR=staging
flutter build ios --simulator --no-codesign --flavor prod --dart-define=FLAVOR=prod
```

macOS:
```sh
flutter build macos --debug --flavor dev --dart-define=FLAVOR=dev
flutter build macos --debug --flavor staging --dart-define=FLAVOR=staging
flutter build macos --debug --flavor prod --dart-define=FLAVOR=prod
```

## Code Signing Notes
iOS:
- Verify bundle IDs + provisioning profiles per flavor.
- Set `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER` in the flavor configs.
- Update entitlements in `ios/Runner/Runner.entitlements` if new capabilities
  are added (e.g., HealthKit, push notifications).
- Use `tool/ios/export_team_ids.sh` to audit scheme team IDs.

macOS:
- Confirm bundle IDs + provisioning profiles per flavor.
- Ensure the macOS entitlements match any required capabilities
  (`macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`).

Android:
- Use `tool/ops/create_android_keystore.sh` to generate a release keystore.
- Store keystore credentials in `android/key.properties` or CI secrets.

## GitHub Actions CI
CI runs on macOS runners in `.github/workflows/ci.yml`:
- `flutter analyze`
- `flutter test`
- Android/iOS/macOS flavor builds per `dev`, `staging`, `prod`

If secrets are required (API keys, Firebase, RevenueCat), use
`tool/ci/generate_dart_define_file.dart` and supply the base64 payload via
`DART_DEFINE_<FLAVOR>` GitHub secrets.
