# Flavor CI Expansion Plan

This document captures actionable steps to extend CI coverage across dev/staging/prod flavors per checklist item **19. Release Prep & Operations** and follow-up automation needs.

## 1. Goals
- Validate Firebase configuration per flavor on every pull request.
- Produce downloadable artifacts (AAB/IPA or simulator builds) for QA without manual steps.
- Keep pipeline runtimes within 20 minutes by leveraging caching and parallelism.

## 2. High-Level Pipeline
1. **Prepare Environment**
   - Install Flutter (pin to `3.35.3`), Dart `3.9.2`.
   - Restore pub packages (`flutter pub get`).
   - Cache `.pub-cache` and `build/` outputs keyed by `os-flavor-lockfile-hash`.
2. **Static Analysis & Unit Tests**
   - `flutter analyze` (single run).
   - `flutter test --coverage` (no flavor needed).
3. **Flavor Matrix Builds**
   - Matrix over `dev`, `staging`, `prod`.
   - For each, run:
     ```bash
     flutter test --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --platform chrome
     flutter build apk --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR
     flutter build ios --simulator --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR
     ```
   - Upload resulting APK + `.app` bundle as artifacts (`build/app/outputs/flutter-apk/`, `build/ios/iphonesimulator/`).
4. **Optional Release Jobs**
   - Nightly or tagged builds can trigger `flutter build appbundle` and `flutter build ios --no-codesign` (requires signing secrets).

## 3. GitHub Actions Sample
```yaml
name: flutter-flavor-ci

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  analyze_test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.3'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage

  flavored-builds:
    needs: analyze_test
    runs-on: macos-14
    strategy:
      fail-fast: false
      matrix:
        flavor: [dev, staging, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.3'
      - run: flutter pub get
      - run: flutter test --flavor ${{ matrix.flavor }} --dart-define=FLAVOR=${{ matrix.flavor }} --platform chrome
      - run: flutter build apk --flavor ${{ matrix.flavor }} --dart-define=FLAVOR=${{ matrix.flavor }}
      - run: flutter build ios --simulator --no-codesign --flavor ${{ matrix.flavor }} --dart-define=FLAVOR=${{ matrix.flavor }}
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.flavor }}-artifacts
          path: |
            build/app/outputs/flutter-apk/
            build/ios/iphonesimulator/
```
> Add `GH_TOKEN` or App Store Connect keys later if notarized builds are required.

## 4. Secrets & Environment
| Secret | Purpose | Storage |
|--------|---------|---------|
| `PLAY_KEYSTORE_BASE64` | Android release keystore (nightly/tag builds only) | Encrypted repo secret |
| `PLAY_KEYSTORE_PASS`, `PLAY_KEY_PASS` | Keystore passwords | Encrypted repo secret |
| `APPLE_API_KEY`, `APPLE_API_ISSUER`, `APPLE_API_KEY_ID` | Required once signed iOS uploads trigger | Encrypted repo secret |
| `FIREBASE_TOKEN` | If deploying hosting/functions after tests | Optional |

## 5. Runtime Optimizations
- Cache `~/.pub-cache` and `build` directories keyed by `pubspec.lock` SHA.
- Use `--simulator` for iOS to avoid code signing until Step 19.1 finishes.
- Mark `fail-fast: false` so one flavor failure doesn’t cancel others; surfaces configuration drift quickly.

## 6. Next Steps
1. Decide on CI provider (GitHub Actions vs Bitrise vs Codemagic) and translate the job accordingly. (DONE) GitHub Actions 선택.
2. Workflow draft now lives at `.github/workflows/flavor-ci.yml`; wire it into your chosen provider or adapt the steps if migrating elsewhere. (DONE) 최신 버전 커밋됨.
3. Configure required secrets (start with none; only add when running release jobs).
4. Dry-run the pipeline on a feature branch; iterate on cache keys and artifact paths. _TODO – 캐시 hit 로그/아티팩트 사이즈 캡처 예정._
5. Update `docs/implementation_checklist.md` item 19 once artifacts are available in CI.
