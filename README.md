# Life App

Life App is an offline-first wellness companion built with Flutter. It unifies
focus, rest, workout, and sleep flows inside a timer-centric workspace, keeps
data encrypted in Isar, syncs lightly through Firestore, and exposes hooks for
RevenueCat, wearable integrations, and remote config experiments.

---

## Table of contents
1. [Feature highlights](#feature-highlights)
2. [Architecture in practice](#architecture-in-practice)
3. [Getting started](#getting-started)
4. [Workflow & tooling](#workflow--tooling)
5. [Assets & localization](#assets--localization)
6. [Project layout](#project-layout)
7. [Documentation index](#documentation-index)
8. [Testing](#testing)
9. [Roadmap](#roadmap)
10. [Contributing](#contributing)
11. [🇰🇷 한국어 요약](#-한국어-요약)

---

## Feature highlights
- **Multi-mode timer engine**: Pomodoro, micro-breaks, HIIT, workout navigator,
  and smart sleep routines live under `lib/features/timer/`. The controller
  supports background execution, foreground services, notifications, and the
  revamped Figma-inspired dashboards.
- **Improved dashboards**: Home surfaces quick actions, mid-term streaks, and
  integration nudges with cards built from Riverpod selectors, plus the new
  Life Buddy persona page (`lib/features/home/`).
- **Encrypted backup & restore**: Zip the Isar database, sync to Drive/iCloud,
  and schedule reminders with `lib/services/backup/` + `lib/features/backup/`.
- **Selective sync**: Change logs replicate settings and summaries through
  Firestore; conflict resolution lives in `lib/providers/sync_providers.dart`.
- **Sleep sound analysis**: Proof-of-concept recorder + analyzer for ambient
  sound, with summary storage and permission gating.
- **RevenueCat integration**: Cached premium state, paywall variants, and
  cross-domain analytics hooks in `lib/services/subscription/`.
- **Community & quests**: Challenges, journals, stats, onboarding variants, and
  accessibility helpers expose provider-based state for tests.

## Architecture in practice
- **Frameworks**: Flutter `3.35.3`, Dart `3.9.2`, Riverpod `3.0`, Firebase SDKs.
- **Data**: Isar collections for settings, sessions, summaries, challenges, and
  change logs (see `docs/data_schema.md`).
- **Providers**: Feature modules own their providers; shared concerns sit under
  `lib/providers/` (auth, sync, settings, analytics, diagnostics, etc.).
- **Services**: `lib/services/` wraps analytics, remote config, background
  guards, audio, backup, subscription, and accessibility logic.
- **Flavors**: `dev`, `staging`, `prod` via Gradle product flavors +
  `--dart-define FLAVOR=<name>` on Flutter side.

## Getting started
1. Install the **Flutter 3.35.3** SDK and Android/iOS toolchains (see
   `docs/foundation.md`).
2. Configure Firebase for each flavor and generate `firebase_options_*.dart`
   using `flutterfire configure` (`docs/environment_config.md`).
3. Provide required secrets (RevenueCat keys, API tokens) through
   `--dart-define` or `.env.<flavor>` files.
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the formatter before committing:
   ```bash
   dart format .
   ```
6. Launch the app with your target flavor (dev example):
   ```bash
   flutter run --flavor dev -t lib/main.dart
   ```
7. For CI parity run:
   ```bash
   flutter analyze
   flutter test
   ```

## Workflow & tooling
- **Formatting**: CI runs `dart format --output=none --set-exit-if-changed .`.
  Ensure you run `dart format .` locally and commit the changes.
- **Analyzer**: `flutter analyze` catches lint + Riverpod issues; keep the
  workspace clean before pushing.
- **Figma exports**: `tool/pull_figma_assets.dart` fetches the latest assets.
- **Scripts**: `tool/` holds helpers for smoke tests, perf benchmarks, and
  automation (use `dart run tool/<script>.dart`).

## Assets & localization
Design remains in Figma; this repo only stores exported assets.

1. Obtain the file key & node IDs from designers.
2. Update `tool/figma_assets.json` with entries such as:
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
3. Generate a personal token: <https://www.figma.com/developers/api>.
4. Pull assets:
   ```bash
   FIGMA_PERSONAL_TOKEN=xxxx dart run tool/pull_figma_assets.dart \
     --manifest tool/figma_assets.json \
     --out assets/figma_exports
   ```
5. Commit exported files with your feature branch. The script handles PNG/SVG,
   multiple densities, and animation JSON.

Localization lives in `lib/l10n/`. When editing ARB files, run
`flutter gen-l10n` (handled automatically by Flutter build).

## Project layout
- `lib/main.dart`: App bootstrap, localization, tab scaffolding.
- `lib/features/`: Timer, backup, stats, journal, onboarding, subscription,
  sleep, community, workout, etc.
- `lib/providers/`: Riverpod providers for auth, sync, settings, sessions,
  backup, analytics, permissions.
- `lib/services/`: Audio, analytics, backup, subscription, remote config,
  accessibility, and diagnostics.
- `lib/widgets/`: Shared UI (glass cards, tab bar, modern cards, etc.).
- `docs/`: Architecture notes, ops guides, roadmap, release playbooks.
- `test/`: Unit + widget coverage (timer, backup, onboarding, journal).

## Documentation index
- Implementation roadmap – `docs/implementation_checklist.md`
- Environment & secrets – `docs/environment_config.md`
- Timer engine – `docs/timer_engine.md`
- Backup & restore – `docs/backup_restore.md`
- Firebase setup – `docs/firebase_setup.md`
- Release prep – `docs/release/release_prep_plan.md`
- Sleep sound PoC – `docs/features/sleep_sound_analysis_poc.md`

## Testing
- Run everything:
  ```bash
  flutter test
  ```
- Key suites:
  - `test/features/timer/` – timer controller, workout entry flow.
  - `test/services/backup_service_test.dart` – encrypted backup logic.
  - `test/features/home/...` – dashboard widgets & provider overrides.
- **Timer UI harness**: Follow
  `test/features/timer/timer_page_workout_entry_test.dart` to override async
  providers, load fake localizations, and pump `TimerPage` without foreground
  services when writing new widget tests.

## Roadmap
- Finish DND prompts + TTS cues for timers.
- Ship production-ready sleep sound analysis UI and policy docs.
- Harden release pipeline (signing, multi-flavor builds, broader CI).
- Expand community challenges: backend sync, seasonal templates, premium
  rewards.
- Explore AI-guided sessions and widgets as per roadmap sections 20–21.

## Contributing
- Keep docs updated when introducing new services or workflows.
- Follow existing Riverpod patterns (Notifier/AsyncNotifier).
- Always run `dart format .`, `flutter analyze`, and `flutter test` before
  pushing/pulling requests.
- Prefer provider overrides and modular services for testability.

---

## 🇰🇷 한국어 요약

라이프 앱은 **Pomodoro/휴식/운동/수면 루틴을 하나의 타이머 허브로 묶은 웰니스
동반자**입니다. 모든 데이터는 로컬 Isar DB에 암호화 저장되고, Firestore로 최소한만
동기화되며, RevenueCat·원격 설정·웨어러블 연동을 염두에 두고 설계되었습니다.

### 핵심 기능
- 다중 모드 타이머 엔진(포커스·마이크로 브레이크·HIIT·수면 모드)과 새로운
  대시보드 위젯, 수면 사운드 분석 체험판.
- 암호화된 백업/복원, 설정·일일 요약 동기화, 커뮤니티 챌린지, 리워드·퀘스트 시스템.
- RevenueCat 기반 구독 UX, 원격 설정 A/B, 접근성(TTS·오디오 알림) 지원.

### 개발 환경
- Flutter 3.35.3 / Dart 3.9.2 / Riverpod 3.0 / Firebase.
- 프로젝트 루트에서 `flutter pub get`, `dart format .`, `flutter analyze`,
  `flutter test`를 실행한 뒤 `flutter run --flavor dev -t lib/main.dart`로 구동합니다.
- Flavor별 Firebase 설정과 비밀키는 `docs/environment_config.md`를 참고하세요.

### 문서 & 구조
- `lib/features/`에 각 기능 모듈, `lib/providers/`에 Riverpod 프로바이더,
  `lib/services/`에 공통 서비스, `docs/`에 아키텍처와 운영 문서가 모여 있습니다.
- Figma 에셋은 `tool/pull_figma_assets.dart`로 내려받아
  `assets/figma_exports/`에 보관합니다.

### 기여하기
- 새 기능을 추가할 때 관련 문서를 갱신하고, Riverpod 패턴을 따라
  테스트 가능한 구조를 유지해주세요.
- PR 전에는 반드시 `dart format .`, `flutter analyze`, `flutter test`를 통과해야 합니다.

---
