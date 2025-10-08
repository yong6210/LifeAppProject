# Accessibility QA Report — 2025-02-20

## Overview
- **Build**: iOS 1.0.0 (100), Android 1.0.0 (100)
- **Devices**:
  - iPhone 14 Pro (iOS 17.2)
  - Pixel 7 (Android 14)
- **Tester**: QA
- **Objective**: Validate screen reader, reduced motion, and color contrast accessibility requirements for MVP.

## 1. Screen Reader (VoiceOver / TalkBack)
- **Home Dashboard**
  - ✓ Routine cards read with clear labels ("Focus routine, button").
  - ✓ Quick actions expose semantics; order matches visual layout.
- **Timer Page**
  - ✓ Timer status announces remaining time every 30s via live region.
  - ✕ Issue: Sleep sound mixer slider not announcing current value (TalkBack). *Action*: Add `semanticFormatterCallback` to sliders.
- **Account Page**
  - ✓ Backup CTA and diagnostics export include descriptive hints.
- **Paywall**
  - ✓ Package cards have semantic summary; purchase button announces price.

## 2. Reduced Motion & Haptics
- Enabled `Account ▸ Accessibility ▸ Reduce motion`. Verified:
  - ✓ Timer progress animation replaced with static updates.
  - ✓ Haptics suppressed on segment transitions.
  - ✕ Issue: Sleep routine entry still vibrates when enabling smart alarm. *Action*: Gate haptic call behind accessibility setting.

## 3. Color/Contrast
- Checked using Stark plugin + manual observation:
  - ✓ Primary text/background combinations meet 4.5:1.
  - ✓ Chips on Stats page meet large-text contrast (3:1).
  - ✓ Error banners (sync failure) meet 4.5:1.

## 4. Dynamic Type / Text Scaling
- iOS large accessibility size:
  - ✓ Timer controls wrap correctly into multiple rows.
  - ✕ Issue: Backup history badge truncates timestamp (overflows). *Action*: Allow multi-line wrap.
- Android font size 130%:
  - ✓ Account cards expand vertically; no clipping observed.

## 5. Keyboard / Switch Control
- macOS build via Catalyst (internal):
  - ✓ Tab focus order follows visual structure on home screen.
- Android Switch Access:
  - ✓ Quick actions reachable; highlight visibility acceptable.

## Summary of Findings
| ID | Area | Severity | Notes | Owner |
| -- | ---- | -------- | ----- | ----- |
| A11Y-01 | Timer → Sleep mixer slider | Medium | TalkBack does not announce slider value | Fixed in app (2025-02-21); re-test pending |
| A11Y-02 | Timer → Sleep routine haptic | Low | Reduced motion toggle not applied | Fixed in app (2025-02-21); re-test pending |
| A11Y-03 | Account → Backup history chip | Medium | Timestamp truncates at large text | Fixed in app (2025-02-21); re-test pending |

## Next Steps
1. Re-test A11Y-01..03 fixes on latest build and update this log with results.
2. Maintain regression coverage on both platforms; aim for a clean report before launch.

_Report archived in `docs/testing/runs/2025-02-20_accessibility.md`._
