# Foundation Configuration Snapshot

## Flutter Toolchain
- Flutter 3.35.3 (stable channel)
- Dart 3.9.2, DevTools 2.48.0

## Platform Targets
- Android: minSdk 24, targetSdk 36, compileSdk 36, Java/Kotlin 17
- iOS: deployment target 15.0

## Continuous Integration Baseline
- GitHub Actions matrix (to be created) running on `macos-latest`
  - Job 1: `flutter analyze`, `flutter test`
  - Job 2: Android assemble (`flutter build apk --debug`)
  - Job 3: iOS build verification (`flutter build ios --no-codesign`)
- Enforce formatting with `dart format --output=none --set-exit-if-changed .`

> Update this document if toolchains or platform requirements change.
