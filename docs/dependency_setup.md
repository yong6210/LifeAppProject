# Core Dependency Setup Notes

## Firebase (Core/Auth/Firestore/Analytics/Crashlytics)
- Run `dart pub global activate flutterfire_cli` and `flutterfire configure` for each Firebase project environment (dev, prod).
- Add generated `firebase_options.dart` under `lib/core/firebase/` and initialize via `Firebase.initializeApp()` in `main.dart`.
- Place `GoogleService-Info.plist` in `ios/Runner/` and `google-services.json` in `android/app/`.
- Update iOS `Info.plist` and Android `AndroidManifest.xml` with URL schemes for Google/Apple sign-in as required.
- Enable Email, Google, Apple sign-in providers in Firebase Console and configure OAuth redirect URIs.
- For Crashlytics, enable crash reporting in the Firebase console and add run scripts:
  - iOS: add `"${PROJECT_DIR}/../flutter/flutterw" crashlytics` run script phase if using FlutterFire Crashlytics integration guidance.
  - Android: apply `com.google.firebase.crashlytics` plugin and add `firebaseCrashlytics { mappingFileUploadEnabled true }` in `app/build.gradle.kts`.

## RevenueCat (`purchases_flutter`)
- Create RevenueCat project and copy platform-specific API keys.
- Add entitlement and product mappings (monthly, annual) matching App Store / Play product identifiers.
- Initialize SDK during app bootstrap using Firebase Auth UID for `appUserID` to support cross-platform recognition.
- Configure listener for CustomerInfo updates to refresh entitlement cache when connectivity changes.

## Isar
- Ensure Isar build runner is wired by adding `build_runner` to dev deps and running `dart run build_runner build --delete-conflicting-outputs`.
- iOS & Android: no additional native configuration required; generated bindings live in `lib/`.

## Flutter Local Notifications
- iOS: request notification permissions and add `UNUserNotificationCenter` delegate bridging via `@UIApplicationMain` in `AppDelegate`.
- Android: ensure channel definitions exist and add receiver/service declarations in `AndroidManifest.xml` if advanced scheduling is needed.

## Cryptography (AES-256-GCM)
- Key generation stored per platform: iOS Keychain (Secure Enclave preferred) and Android Keystore (`KeyGenParameterSpec` with `setIsStrongBoxBacked(true)` when available).
- Use `cryptography`'s `AesGcm.with256bits()` for backup archive encryption.

Revisit this document whenever dependencies change or new platform requirements emerge.
