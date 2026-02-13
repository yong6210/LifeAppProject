# Product Features Roadmap

This document scopes the next product features and lists the work needed to
ship them safely.

## Guided Sessions
Goal: scripted focus/workout/sleep sessions with audio cues and milestone steps.

Scope:
- Session templates with step timing, labels, and optional cues.
- UI to browse/select templates per mode.
- In-session progress view with step timeline.

Checklist:
- [x] Define `GuidedSessionTemplate` model (runtime templates)
- [ ] Add template seed data + migration strategy
- [x] Build template picker UI in timer flow (`guided_session_picker_page.dart`)
- [x] Add step timeline + current step highlight
- [x] Hook audio/voice cues to step transitions
- [x] Add analytics events for starts/completions (KPI schema events)
- [x] Tests for picker entry and navigation flow

Status note:
- Guided Sessions MVP shipped with template picker + multi-step execution via
  `TimerPage(initialRoutine: ...)`.
- Added guided run progress card, TTS step cues, and completion loop sheet
  (restart/home action).
- Remaining work is persistence/migrations and optional richer visual timeline.

## AI Recommendations (Phase 1: Rules-Based)
Goal: personalized suggestions without sending private data off-device.

Scope:
- Local signals: routines, session streaks, sleep summary, workout history.
- Rules-based engine first, ML later.
- Recommendations surfaced in Home + Stats.

Checklist:
- [x] Define recommendation inputs + a small rules engine
- [x] Add storage for dismissed/accepted recommendations (SharedPreferences)
- [x] Wire to home dashboard card (with CTA + dismiss)
- [x] Instrument usage analytics (accept/dismiss)
- [ ] Add test coverage for rule outputs

Status note:
- Rules-based recommendation engine is active in `CasualHomeDashboard` through
  `dailyRecommendationProvider`.

## Home Screen Widgets
Goal: quick glance + tap-to-start for focus/sleep/workout.

Scope:
- iOS widget + Android app widget.
- Surface: next session, last sleep score, quick start actions.
- Refresh policy aligned with platform limits.

Checklist:
- [x] Define widget data payload fields (completion + next action)
- [x] Update `WidgetUpdateService` to publish new data
- [ ] Ensure background refresh policies for iOS + Android
- [ ] Add deep link handling to start timers
- [ ] Document widget permissions + limitations
- [ ] End-to-end test on device for update latency

Status note:
- Widget payload now includes normalized completion and next action hints.
