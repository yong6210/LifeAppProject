# Release Prep & Operations Plan

This document captures concrete steps and owners required to complete Checklist **19. Release Prep & Operations**. Items are ordered in the recommended sequence so the team can execute and check them off.

---

## 1. iOS Signing Readiness

| Task | Owner | Prerequisites | Notes |
|------|-------|---------------|-------|
| Ensure Apple Developer Program account is active and the correct Team is available | PM / Admin | Apple Developer access | Verify that each flavor (dev, staging, prod) will map to the right bundle ID and App ID in App Store Connect. |
| Open `ios/Runner.xcworkspace`, select Runner target, and assign Team for all configurations (Debug/Release + dev/staging/prod) | iOS dev | Above | Screenshots should be stored for future auditing. |
| Generate or refresh provisioning profiles per flavor (automatic provisioning preferred) | iOS dev | Above | Confirm the proper bundle IDs exist in App Store Connect; regenerate if identifiers changed. |
| Register physical test devices (at least one per flavor) | QA | Above | Needed only if on-device tests will run before release. |
| Clear build caches when disk space is tight before running flavor builds | iOS dev | Above | `rm -rf build/` frees >30 GB locally; run again if Xcode reports “No space left on device”. |

### Flavor → Bundle/App Mapping
| Flavor | Bundle Identifier | Firebase Project | Suggested App Store Connect App | Notes |
|--------|-------------------|------------------|-------------------------------|-------|
| dev | `com.ymcompany.lifeapp.dev` | `life-app-dev` | `Life App Dev` (Internal) | Use a development provisioning profile. Automatic signing is fine. |
| staging | `com.ymcompany.lifeapp.staging` | `life-app-ed218` | `Life App Staging` (TestFlight only) | Keep distribution certificate optional; focus on Ad Hoc/TestFlight. |
| prod | `com.ymcompany.lifeapp` | `life-app-prod-8b6e4` | `Life App` (Production) | Requires distribution certificate and App Store provisioning profile. |

**Xcode checklist**
1. `open ios/Runner.xcworkspace`
2. Select the Runner project → *Targets* → `Runner`
3. For each combination of *Configuration* (`Debug`, `Release`, `Profile`) and *Flavor* (`dev`, `staging`, `prod`):
   - Confirm the `Bundle Identifier` matches the table above
   - Set `Team` to your Apple Developer Team
   - If manual signing is used, point to the correct provisioning profile
4. Repeat for the `RunnerTests` target if UI tests will be signed.

> Tip: `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showBuildSettings | rg "DEVELOPMENT_TEAM"` can be used to verify the configured Team IDs from the command line.

### Validation Command
```bash
flutter build ios --flavor dev --dart-define=FLAVOR=dev
flutter build ios --flavor staging --dart-define=FLAVOR=staging
flutter build ios --flavor prod --dart-define=FLAVOR=prod
```
> If signing is incomplete you will see the "Development Team" error. Otherwise the command should produce signed `.ipa` artifacts in `build/ios/archive/`.

---

## 2. Android Release Signing

| Task | Owner | Prerequisites | Notes |
|------|-------|---------------|-------|
| Create release keystore (if not yet created) and store it securely (e.g., 1Password) | Android dev | Security policy approval | Example: `keytool -genkey -v -keystore life_app.jks -alias life_app -keyalg RSA -keysize 2048 -validity 10000`. |
| Update `android/app/build.gradle.kts` with release signingConfigs referencing environment variables | Android dev | Keystore path/passwords | Consider using `gradle.properties` with encrypted values committed to secure storage. |
| Verify Play Console package names exist (dev/staging/prod tracks) | PM | Firebase IDs ready | Create internal testing tracks if they do not exist. |

### Validation Command
```bash
flutter build appbundle --flavor dev
flutter build appbundle --flavor staging
flutter build appbundle --flavor prod
```
> Inspect the resulting `.aab` files under `build/app/outputs/bundle/**/`. Upload to Play Console Internal Testing for smoke verification.

---

## 3. Continuous Integration Updates

| Task | Owner | Notes |
|------|-------|-------|
| Update GitHub Actions (or chosen CI) to build dev/staging/prod flavors | DevOps | Add a strategy matrix for flavors and run `flutter test`, `flutter build apk/appbundle`, `flutter build ios --simulator`. |
| Configure CI secrets (keystore passwords, Apple API keys if required) | DevOps / Security | Use encrypted secrets storage. |
| Add artifact uploads (AAB/IPA) to help QA download builds quickly | DevOps | Optional but recommended. |

Sample matrix snippet for GitHub Actions:
```yaml
strategy:
  matrix:
    flavor: [dev, staging, prod]
steps:
  - run: flutter test --flavor ${{ matrix.flavor }} --dart-define=FLAVOR=${{ matrix.flavor }}
  - run: flutter build appbundle --flavor ${{ matrix.flavor }}
  - run: flutter build ios --simulator --flavor ${{ matrix.flavor }} --dart-define=FLAVOR=${{ matrix.flavor }}
```
> Note: Signed iOS builds require additional Apple authentication (App Store Connect API key or `xcodebuild` with manual signing). Keep simulator builds in CI until signing automation is ready.

---

## 4. Checklist Completion Criteria
- [ ] `flutter build ios --flavor prod` succeeds locally with signed output.
- [ ] `flutter build appbundle --flavor prod` succeeds locally and uploads to Play Console internal testing.
- [ ] CI pipeline produces artifacts per flavor and runs unit tests. Manual sign-off recorded in release checklist.

When all three are checked the global checklist item **19. Release Prep & Operations** can be marked complete.
