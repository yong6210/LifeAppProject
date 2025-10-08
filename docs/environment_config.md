# Environment & Secrets Strategy

## Flavors
- Define Flutter flavors: `dev`, `staging`, `prod` using Gradle productFlavors and Xcode build configurations.
- Pass `--dart-define=FLAVOR=<dev|staging|prod>` to `flutter run`/`flutter build` so the app selects the right Firebase project (see `lib/core/firebase/firebase_options_factory.dart`). The default without a define is `staging` to mirror CI smoke tests.

## Firebase Projects
- Maintain separate Firebase projects per flavor. Generate `firebase_options_dev.dart`, `firebase_options_staging.dart`, `firebase_options_prod.dart` via `flutterfire configure` and keep `firebase.json` in sync so regenerated files land in the correct flavor directories.
- Expose an abstract `FirebaseConfig` interface in `lib/core/config/firebase_config.dart` and select implementation based on `FLAVOR`.
- Keep Firestore security rules under version control (`firebase/firestore.rules`) and deploy them per project with `firebase deploy --only firestore:rules --project <project-id>` whenever the rules change.

### Remote Config Flags
- `sleep_sound_enabled`: gates the Android foreground service for the sleep sound analysis PoC. Defaults to `true` if absent so local builds continue to function.

## Secrets Management
- Avoid checking API keys into source control.
- Store secret values (RevenueCat public API key, Sentry DSN, optional) in `.env.<flavor>` files tracked by `git-crypt` or environment-specific secret storage.
- Load secrets using `--dart-define-from-file=.env.dev` (supported by Flutter 3.13+) during CI and local runs.
- For native platform secrets (Android `local.properties`, iOS `Config.xcconfig`), maintain template files with `_example` suffix under version control.

### RevenueCat
- Provide the public SDK keys using `--dart-define` values:
  - `REVENUECAT_ANDROID_KEY`
  - `REVENUECAT_IOS_KEY`
- During local development create `.env.dev` with:
  ```
  REVENUECAT_ANDROID_KEY="public_sdk_key_android"
  REVENUECAT_IOS_KEY="public_sdk_key_ios"
  ```
- Production builds must inject the production keys via CI secrets. The app defaults to placeholder strings if the keys are missing, and the RevenueCat subsystem becomes a no-op.

## Build Automation
- Update CI workflows to pass the appropriate dart defines and to pull secure files from encrypted storage (GitHub Actions secrets + secure artifacts).
- Document onboarding steps in `/docs/onboarding.md` (to be created) to ensure new developers can set up credentials safely.

Keep this document updated as new services (e.g., analytics, monitoring) introduce additional configuration.
