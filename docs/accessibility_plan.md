# Accessibility Plan (v1.1)

## 1. Screen Reader Support
- Audit key screens (Home, Timer, Stats, Backup, Paywall, Account) with VoiceOver and TalkBack.
- Ensure semantic widgets wrap controls (`Semantics`, `MergeSemantics`, `ExcludeSemantics` tuned) and provide `tooltip`/`semanticLabel` for icon-only buttons.
- Timer screen: announce remaining time updates via a throttled live region helper every 30 seconds (or when segment changes) to avoid chatter.

## 2. Dynamic Type & Layout
- Respect `MediaQuery.textScaleFactor`; cap non-critical text at 1.3x but allow wrapping and vertical stacking when needed.
- Use `LayoutBuilder` breakpoints to switch button rows to columns when width < 360dp or scale > 1.2.
- Ensure timer control bar buttons remain ≥48x48dp.

## 3. Contrast & Themes
- Follow tokens in `docs/design_system.md` (≥4.5:1 for text-on-surface, ≥3:1 for large text). Verify light/dark themes.
- Provide manual QA using tools (Xcode Accessibility Inspector, Android Accessibility Scanner, Stark plugin).

## 4. Reduced Motion & Haptics
- Add `Settings` toggle for reduced motion affecting: timer animations (progress indicator updates), screen transitions, haptic feedback.
- Respect `MediaQuery.of(context).accessibleNavigation` before triggering vibrations or auto-animations.

## 5. Testing Checklist
- [x] VoiceOver run (iOS latest): verify focus order in dashboard, timer controls, paywall. *(A11Y-01 fix applied Feb 2025 — slider semantics updated; re-test scheduled.)*
- [x] TalkBack run (Android latest): ensure routine cards and quick actions read clearly. *(A11Y-01 fix applied; awaiting confirmation.)*
- [x] Dynamic Type (largest size): ensure text wraps and no truncation on timer/tables. *(A11Y-03 fix applied; timestamp now wraps.)*
- [x] Reduced motion toggle: confirm animations suppressed and haptics bypassed when enabled. *(A11Y-02 fix applied; reduced motion bypasses adaptive switches.)*
- [x] Color blindness sims: charts/badges remain distinguishable.
- [x] Keyboard/trackpad navigation (Chromebook/desktop): tab order logical, focus ring visible.

## 6. Implementation Tasks
- [x] Introduce shared `AccessibilityController` storing `reducedMotion` preference (persist in `Settings`).
- [x] Wrap Timer control buttons and quick actions with `Semantics` descriptions (e.g., "Start focus routine").
- [x] Implement `AccessibleTimerAnnouncer` (imported via provider) to throttle live region updates.
- [x] Add `Semantics` hints to premium upsell and paywall CTAs indicating benefit. *(Completed Feb 2025 — see `lib/features/account/account_page.dart` and `lib/features/subscription/paywall_page.dart`.)*
- [x] Ensure charts have accessible data table toggles.
- [x] Update haptic triggers to respect `AccessibilityController.reducedMotion`.

Evidence: `docs/testing/runs/2025-02-20_accessibility.md`. Fixes for A11Y-01..03 shipped on 2025-02-21; rerun validation to close them out.
