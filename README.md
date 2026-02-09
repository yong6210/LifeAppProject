# Life App

Life App is an offline-first wellness companion built with Flutter. It brings
focus, rest, workout, and sleep experiences into a single timer-centric
workspace while keeping data encrypted locally, synchronised lightly across
devices, and ready for future subscription and wearable integrations.

## Highlights
- **Multi-mode timer engine** with Pomodoro, micro-break, HIIT, and smart sleep
  plans, background resilience, and notification support (`lib/features/timer/`).
- **Sleep Sound Analysis UI** providing users with insights into their sleep quality, including metrics like restful minutes and loud event counts (`lib/features/sleep/`).
- **Firestore-backed Community Challenges** allowing users to create and join challenges that are synced in real-time across devices. Challenge templates are remotely managed via Firebase Remote Config (`lib/features/community/`).
- **Encrypted backup & restore** flows that package the Isar database for drive
  or iCloud hand-off, complete with streak tracking and reminders
  (`lib/services/backup/`).
- **Lightweight sync** via Firestore that reconciles settings and daily summary
  buckets per device using change logs (`lib/core/firebase/`).
- **Subscription-ready UX** using RevenueCat with cached premium state and
  paywall variants (`lib/services/subscription/`).

## Architecture
- **Frameworks:** Flutter 3.x, Dart 3.x, Riverpod 2.x, Firebase.
- **Local data:** Isar collections for sessions, settings, routines, summaries,
  and change logs (`lib/repositories/`).
- **Sync layer:** 
  - `FirestoreSyncService` debounces uploads from change logs and
  fetches remote settings/daily summaries on demand.
  - `CommunityRepository` provides real-time synchronization of community challenges using Firestore streams.
- **Remote Config:** Challenge templates and other feature flags are managed via Firebase Remote Config for dynamic updates.
- **Services:** Modular wrappers for analytics, remote config, notifications,
  background guards, audio, and diagnostics (`lib/services/`).
- **Presentation:** Feature modules under `lib/features/` with Riverpod
  providers mediating state and business logic (`lib/providers/`).

## Project Layout
- `lib/main.dart` – App bootstrap, localization, and home shell.
- `lib/features/` – Timer, backup, stats, journal, onboarding, subscription, community, and sleep feature scopes.
  - `lib/features/community/community_repository.dart` - Firestore logic for challenges.
  - `lib/features/sleep/sleep_analysis_detail_page.dart` - Detailed sleep analysis UI.
  - `lib/features/timer/widgets/sleep_analysis_result_card.dart` - Sleep summary card on the timer page.
- `lib/providers/` – Riverpod providers for auth, sync, sessions, settings,
  backup, feature flags, diagnostics, and accessibility.
- `lib/services/` – Shared services (audio, analytics, notifications, remote
  config, background, database, subscription, backup).
- `lib/models/` – Isar data models and generated adapters.
- `test/` – Unit and widget tests, including coverage for sleep analysis UI and timer functionalities.

## Key Documentation
- `README.md` - Project overview, architecture, and testing
- `TODO.md` - Active checklist for upcoming work
- `docs/release_readiness.md` - Release checklist, signing, and CI guidance
- `docs/product_features.md` - Product feature roadmap
- `docs/community_challenges.md` - Community challenges expansion plan
- `docs/privacy_sleep_sound.md` - Sleep sound analysis privacy notes
- `docs/design_review.md` - UI/UX review notes

## Secrets & Firebase Config
- This repository is public, so real Firebase configs and signing keys are not committed.
- Use the `*.example` files as templates and create the real files locally.
- You can regenerate Firebase configs with `flutterfire configure`.
- CI should inject the real files from secrets before builds.

## Testing
- Run all tests:
  ```shell
  flutter test
  ```
- Focused suites cover timer controller behaviour (`test/timer/`), encrypted
  backup workflows (`test/backup_service_test.dart`), and the sleep analysis card UI (`test/features/timer/sleep_analysis_card_test.dart`).
- When adding new UI components, especially those dependent on Riverpod providers, follow the pattern in `sleep_analysis_card_test.dart` for creating isolated, testable widgets.

## Roadmap & Open Work
- **Completed:**
  - **DND prompt for focus mode:** Verified existing implementation in `timer_page.dart`.
  - **Text-to-speech cues for workout mode:** Verified existing implementation in `timer_controller.dart`.
  - **Sleep sound analysis UI:** Implemented summary card and detail page.
  - **Community challenges backend sync:** Migrated from local seed data to a Firestore-backed repository.
  - **Seasonal templates for challenges:** Implemented remote management of templates via Firebase Remote Config.

- **Next Steps:**
  - **Prepare release operations:** Code signing, flavor builds, and expanded CI.
  - **Develop competitive features:** Guided sessions, AI recommendations, and home screen widgets.
  - **Enhance Community Challenges:** Implement full user profile integration (beyond `ownerId` stubs) and premium rewards.
  - **Policy Documentation:** Create documentation for sleep sound analysis privacy and data handling.

## Contributing
- Keep this `README.md` up to date when adding services or workflows.
- Follow existing Riverpod patterns (AsyncNotifier) and ensure new
  features expose providers for testability.
- Run `flutter analyze`, `flutter test`, and platform build checks in CI before
  merging feature branches.
