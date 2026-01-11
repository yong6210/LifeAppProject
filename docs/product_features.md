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
- [ ] Define `GuidedSessionTemplate` model and persistence in Isar
- [ ] Add template seed data + migration strategy
- [ ] Build template picker UI in timer flow
- [ ] Add step timeline + current step highlight
- [ ] Hook audio/voice cues to step transitions
- [ ] Add analytics events for starts/completions
- [ ] Tests for template parsing + step transitions

## AI Recommendations (Phase 1: Rules-Based)
Goal: personalized suggestions without sending private data off-device.

Scope:
- Local signals: routines, session streaks, sleep summary, workout history.
- Rules-based engine first, ML later.
- Recommendations surfaced in Home + Stats.

Checklist:
- [ ] Define recommendation inputs + a small rules engine
- [ ] Add storage for dismissed/accepted recommendations
- [ ] Wire to home dashboard card (with CTA)
- [ ] Instrument usage analytics (accept/dismiss)
- [ ] Add test coverage for rule outputs

## Home Screen Widgets
Goal: quick glance + tap-to-start for focus/sleep/workout.

Scope:
- iOS widget + Android app widget.
- Surface: next session, last sleep score, quick start actions.
- Refresh policy aligned with platform limits.

Checklist:
- [ ] Define widget view models + refresh schedule
- [ ] Update `WidgetUpdateService` to publish new data
- [ ] Ensure background refresh policies for iOS + Android
- [ ] Add deep link handling to start timers
- [ ] Document widget permissions + limitations
- [ ] End-to-end test on device for update latency
