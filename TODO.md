# Project TODO

This file captures upcoming work items and open tasks for the project.
Source: README.md "Roadmap & Open Work" and current build/test context.

## Release Readiness
- [x] Set up code signing for macOS and iOS builds
- [x] Define flavor builds (dev/staging/prod) and verify configuration
- [x] Expand CI to run `flutter analyze`, `flutter test`, and platform builds

## Product Features
- [x] Guided sessions experience (MVP template picker + multi-step launch)
- [x] AI recommendations (Phase 1 rules engine + feedback persistence)
- [x] Home screen widgets data payload enrichment (completion + next action)

## Community Challenges
- [ ] User profile integration (beyond `ownerId` stubs)
- [ ] Premium rewards for challenges

## Privacy & Policy
- [x] Document sleep sound analysis data handling and privacy policy

## Design Review
- [x] UI review notes captured for all screens

## Design Follow-ups
- [x] Align typography, card elevation, and icon style across Home/Timer/Workout/Sleep tabs
- [x] Define a default background treatment and reserve gradients for hero surfaces
- [x] Standardize primary CTA placement per screen (top-right, bottom CTA, or FAB)
- [x] Localize remaining hard-coded strings (ensure consistent casing)
- [x] Add a clearer “Next action” tile on Home and a stronger anchor for the current workout step

## Build/Run Health
- [x] Ensure macOS Firebase options are configured (FlutterFire for macOS)
- [x] Re-run macOS app launch after Firebase configuration

## Verification Checklist (when shipping)
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `flutter run -d macos`
- [x] `flutter build windows`
- [x] `flutter run -d windows` after NuGet check (`tool/ops/check_windows_nuget.ps1`)

## Growth Strategy (2026 H1)
- [ ] Complete Phase 1 items in `docs/growth_strategy_2026_h1.md`
- [ ] Define KPI dashboard + weekly review ritual
- [x] Ship paywall A/B infra (3 variants + annual emphasis + experiment id)
- [ ] Run paywall A/B operations (copy + annual emphasis) with weekly review
- [x] Standardize KPI event schema + dashboard mapping (`docs/analytics_kpi_dashboard.md`)

## UI 통합 안정화 (2026-02-13)
- [x] 탭 셸 마운트/온보딩 타이밍 안정화 (`lib/main.dart`)
- [x] 홈 진입 우회용 온보딩 건너뛰기 추가 (`lib/features/onboarding/onboarding_page.dart`)
- [x] 하단 탭바 가독성 중심 리디자인 (`lib/widgets/ios_tab_bar.dart`)
- [x] 하단 탭바 최소 터치 타겟/선택 상태 semantics 보강 + 위젯 테스트 추가 (`lib/widgets/ios_tab_bar.dart`, `test/widgets/ios_tab_bar_test.dart`)
- [x] 홈 상세 영역 접이식 전환으로 초기 난잡도 완화 (`lib/features/home/casual_home_dashboard.dart`)
- [x] 홈 인사이트 운동 목표 하드코딩 제거 (`lib/features/home/casual_home_dashboard.dart`)
- [x] 운동 탭 에너지뱅크 목표와 설정값 동기화 (`lib/features/workout/figma_workout_tab.dart`)
- [x] `MyHomePage` 홈 기본 노출 회귀 테스트 추가
- [x] Timer/Workout/Sleep 일부 핵심 문구 한/영 l10n 반영 (`lib/l10n/intl_en.arb`, `lib/l10n/intl_ko.arb`)
- [x] Timer 기본/고급 섹션 분리 + 섹션 전환 회귀 테스트 추가 (`lib/features/timer/timer_page.dart`, `test/features/timer/timer_page_section_switch_test.dart`)
- [x] Timer 마스코트/섹션 전환 잔여 하드코딩 문구 l10n 전환 (`lib/features/timer/timer_page.dart`)
- [x] 하단 탭바 대비 자동 검증 테스트 추가 (`test/widgets/ios_tab_bar_test.dart`)
- [ ] 하단 탭바 접근성/명도 대비 실기기 검증 (Android/iOS)
- [ ] 롤아웃 QA 결과를 `docs/ui_integration_stabilization_master_plan_2026-02-13.md`와 동기화
