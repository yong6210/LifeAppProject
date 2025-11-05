# 라이프 위버

- 기본 공격 : 힐링 블라썸 (Healing Blossom)
꽃을 충전해 발사하는 방식. 완충 후 발사하면 힐이 커지지만, 딜은 거의 없다.
덕분에 “아군이 죽어도 예쁜 꽃잎이 날린다.”

- 보조 공격: 쏜 발사기 (Thorn Volley)
가시를 연사로 쏜다. 공격용이지만 데미지는 딜러에게 욕먹을 수준.
즉, 이걸로 킬하면 그건 네 실력이 아니라 기적이다.

- 스킬 1: 리프 그립 (Life Grip)
아군 한 명을 자기 쪽으로 끌어온다.
팀원을 구할 수도 있지만, 잘못 쓰면 “트롤 그립”으로 욕먹는다.
프로 경기에서는 생명줄, 일반 경기에서는 분노유발 장치.

- 스킬 2: 페탈 플랫폼 (Petal Platform)
바닥에 꽃잎을 깔면 밟은 캐릭터를 공중으로 띄운다.
적이 밟아도 작동한다. 즉, 자폭 D.Va를 하늘로 띄워주는 멋진 장면 연출 가능.

- 스킬 3: 리주버네이팅 대시 (Rejuvenating Dash)
앞으로 짧게 돌진하며 체력을 조금 회복한다.
“움직이는 힐팩.”

- 궁극기: 트리 오브 라이프 (Tree of Life)
나무를 소환해 지속적인 회복과 커버를 제공한다.
하지만 진짜 문제는 그 나무가 거대해서 라인하르트의 시야를 막는다.
“힐은 좋은데 왜 앞이 안 보여?”라는 말 자주 들음.

- 장점

구멍 난 팀플레이를 구조할 수 있는 구세주형 지원가.

지형을 활용해 고지대 전투 지원, 낙사 방지, 팀 전개 조정 가능.

시각적으로 화려해서 스킨값이 아깝지 않다.

- 단점

순간 회복력 부족, 조준 까다로움, 힐 충전 딜레이, 그리고 팀원이 못 알아먹으면 트롤처럼 보임.

- **요약** : 센스와 인내심 없으면 멘탈이 먼저 죽는다.

요약하면, 라이프위버는 **"예쁜데 까다로운 서포터"**다.
잘 쓰면 팀의 구원자, 못 쓰면 팀의 파괴자.


# Life App

Life App is an offline-first wellness companion built with Flutter. It brings
focus, rest, workout, and sleep experiences into a single timer-centric
workspace while keeping data encrypted locally, synchronised lightly across
devices, and ready for future subscription and wearable integrations.

## Highlights
- **Multi-mode timer engine** with Pomodoro, micro-break, HIIT, and smart sleep
  plans, background resilience, and notification support (`lib/features/timer/`).
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
