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
