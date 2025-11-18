# Life App

Life App is an offline-first wellness companion built with Flutter. It brings
focus, rest, workout, and sleep experiences into a single timer-centric
workspace while keeping data encrypted locally, synchronised lightly across
devices, and ready for future subscription and wearable integrations.

## Highlights
- **Multi-mode timer engine** with Pomodoro, micro-break, HIIT, and smart sleep
  plans, background resilience, and notification support (`lib/features/timer/`).
- **iOS-style time picker** for Sleep and Focus modes with 12-hour format,
  AM/PM toggling, looping dials, and automatic hour adjustments when scrolling
  through minute boundaries (`lib/features/sleep/figma_sleep_tab.dart`,
  `lib/features/timer/figma_timer_tab.dart`).
- **Encrypted backup & restore** flows that package the Isar database for drive
  or iCloud hand-off, complete with streak tracking and reminders
  (`lib/services/backup/`, `lib/features/backup/backup_page.dart`).
- **Lightweight sync** via Firestore that reconciles settings and daily summary
  buckets per device using change logs (`lib/core/firebase/`).
- **Sleep sound analysis proof-of-concept** covering recording, amplitude
  analytics, and summary persistence (`lib/services/audio/sleep_sound_analyzer.dart`).
- **Subscription-ready UX** using RevenueCat with cached premium state and
  paywall variants (`lib/services/subscription/`).
- **Personalised coach & community** nudging users toward backups, focus goals,
  and stretch breaks while introducing collaborative challenges, daily quests,
  and in-app rewards (`lib/features/timer/timer_page.dart`, `lib/features/community/`).

## Architecture
- **Frameworks:** Flutter 3.35.3, Dart 3.9.2, Riverpod 3.0, Firebase.
- **Local data:** Isar collections for sessions, settings, routines, summaries,
  and change logs (`lib/repositories/`, `docs/data_schema.md`).
- **Sync layer:** `FirestoreSyncService` debounces uploads from change logs and
  fetches remote settings/daily summaries on demand.
- **Services:** Modular wrappers for analytics, remote config, notifications,
  background guards, audio, and diagnostics (`lib/services/`).
- **Presentation:** Feature modules under `lib/features/` with Riverpod
  providers mediating state and business logic (`lib/providers/`).

## Getting Started
1. Install Flutter 3.35.3 (stable) and set up Android/iOS toolchains
   (`docs/foundation.md`).
2. Configure Firebase projects per flavor and generate `firebase_options_*.dart`
   via `flutterfire configure` (`docs/environment_config.md`).
3. Provide RevenueCat and other secrets via `--dart-define` or `.env.<flavor>`
   files (see docs for examples).
4. Install dependencies:
   ```shell
   flutter pub get
   ```
5. Run the app with a flavor (defaults to `staging` if omitted):
   ```shell
   flutter run --dart-define=FLAVOR=dev
   ```

## Figma Assets & Specs
Design still lives in Figma; the repo only stores the assets Flutter needs.

1. Ask design for the file key and node IDs you want to export (Figma → Inspect).
2. Add or update entries inside `tool/figma_assets.json`:
   ```json
   {
     "fileKey": "ABCD1234efGhIjkLmN",
     "assets": [
       {
         "nodeId": "12:345",
         "name": "journal_calendar_cell",
         "format": "png",
         "scale": 2,
         "output": "journal"
       }
     ]
   }
   ```
3. Generate a personal access token at <https://www.figma.com/developers/api>.
4. Pull the assets (they land in `assets/figma_exports/`):
   ```bash
   FIGMA_PERSONAL_TOKEN=xx dart run tool/pull_figma_assets.dart \
     --manifest=tool/figma_assets.json \
     --out=assets/figma_exports
   ```
5. Commit the downloaded files alongside code changes so everyone stays in sync.

The script uses the Figma Images API, so it works for PNG/SVG and can render
multiple densities (set `scale`). For complex animations export Lottie JSON from
Figma/AE and drop it into `assets/figma_exports/animations/`.

## Project Layout
- `lib/main.dart` – App bootstrap, localization, and home shell.
- `lib/features/` – Timer, backup, stats, journal, onboarding, subscription,
  community, and account feature scopes.
- `lib/providers/` – Riverpod providers for auth, sync, sessions, settings,
  backup, feature flags, diagnostics, and accessibility.
- `lib/services/` – Shared services (audio, analytics, notifications, remote
  config, background, database, subscription, backup).
- `lib/models/` – Isar data models and generated adapters.
- `docs/` – Product, architecture, ops, testing, and roadmap documentation.
- `test/` – Unit and widget tests, including timer and backup coverage.

## Key Documentation
- Implementation checklist and roadmap: `docs/implementation_checklist.md`
- Environment & secrets strategy: `docs/environment_config.md`
- Timer engine design: `docs/timer_engine.md`
- Backup & restore guide: `docs/backup_restore.md`
- Firebase setup: `docs/firebase_setup.md`
- Release preparation: `docs/release/release_prep_plan.md`
- Sleep sound PoC notes: `docs/features/sleep_sound_analysis_poc.md`

## Testing
- Run all tests:
  ```shell
  flutter test
  ```
- Focused suites cover timer controller behaviour (`test/timer/`) and encrypted
  backup workflows (`test/backup_service_test.dart`). Add integration tests for
  new sync or backup flows as they evolve.

### Timer page UI harness
`TimerPage` depends on asynchronous providers (`settingsFutureProvider`,
`todaySummaryProvider`, permissions, etc.) plus localization assets. When adding
widget tests for timer entry points (app bar actions, quick cards, navigator
overlays):
- Follow the pattern in `test/features/timer/timer_page_workout_entry_test.dart`
  by overriding the async providers with synchronous fakes and feeding a fake
  `TimerController`.
- Use the `_TestAppLocalizationsDelegate` helper (see the same test file) so the
  widget tree does not try to load ARB files from disk; load the desired locale
  once in `setUpAll` and hand it to the delegate.
- Pump a `TimerPage(useForegroundTask: false)` to bypass the
  `WithForegroundTask` wrapper that would otherwise stall tests.
- Ensure the `TimerState` starts in the mode your scenario requires; the fake
  controller in the test demonstrates how to pin the mode to `workout`.

Replicate that harness whenever you need to cover additional timer UI flows so
the tests remain deterministic and isolated from platform services.

## Roadmap & Open Work
- Ship the DND prompt for focus mode and text-to-speech cues for workout mode
  (see checklist section 4).
- Complete the sleep sound analysis evaluation, UI, and policy documentation
  (checklist section 18).
- Prepare release operations: code signing, flavor builds, and expanded CI
  (checklist section 19).
- Develop competitive features such as guided sessions, AI recommendations, and
  widgets (checklist sections 20–21).
- Ship community challenges beyond the MVP (backend sync, seasonal templates,
  premium rewards) to deepen retention.

## Contributing
- Keep architecture and ops docs up to date when adding services or workflows.
- Follow existing Riverpod patterns (Notifier/AsyncNotifier) and ensure new
  features expose providers for testability.
- Run `flutter analyze`, `flutter test`, and platform build checks in CI before
  merging feature branches.
