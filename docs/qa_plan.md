# QA & Regression Plan (Draft)

_Last updated: 2025-10-03_

## 1. Automated Coverage

### 1.1 Unit Tests (CI blocking)
- Timer state machine: segment transitions, resume after restore, foreground notification scheduling stubbed.
- Backup service: encryption/decryption integrity, manifest validation, failure logging.
- Firestore sync: conflict merge strategy, device bucket aggregation, change log flushing.
- Subscription gating: premium status provider fallbacks and grace-period handling.

### 1.2 Widget/Integration Tests (CI non-blocking until target milestone)
- Onboarding flow variants (default vs persona-first via remote config stub).
- Account page: premium gate states, backup preview for free users, account deletion confirmation.
- Paywall: missing key placeholder, package list rendering, analytics event smoke.
- Timer page: workout navigator entry (app bar & coach CTA) drives navigation + analytics guardrails.

## 2. Manual Test Matrix (pre-release)

| Scenario | Devices | Notes |
| --- | --- | --- |
| Offline start → timer session → background resume | Pixel 7 (Android 14), iPhone 14 (iOS 17) | Validate foreground service + iOS BG task scheduling. |
| Account deletion flow | Same as above | Ensure local data cleared, Firestore docs deleted (verify via console), user signed out. |
| Backup/restore across platforms | Pixel 7 → iPhone 14 | Export encrypted backup to Drive, import on iOS via Drive app. |
| Lifestyle onboarding presets | Pixel 7, iPhone 14 | Select 0/1/2 lifestyles, confirm preview sheet, presets applied, SharedPreferences entries created. |
| Workout Navigator access | Pixel 7, iPhone 14 | AppBar/coach entry → navigator page, verify GPS prompts, offline fallback instructions, analytics event logged. |
| Subscription purchase & gate | iPhone 14 | Use sandbox RevenueCat keys, verify entitlement caching when offline. |
| Remote-config onboarding variant | Pixel 7 (dev build) | Override RC doc to persona_first, confirm order update. |

## 3. Release Checklist (per store submission)
- ✅ CI pipeline green (unit + widget suites).
- ✅ Manual matrix executed; attach signed test log in release ticket.
- ✅ Crashlytics dashboard reviewed (no new critical crashes in staging build).
- ✅ Privacy policy & data disclosures double-checked against store forms.
- ✅ Backup/export smoke on production Firebase project.

## 4. Tooling & Ownership
- QA owner: TBD (assign in project board).
- Test tracking: Notion “QA Matrix” (create board linked to this doc).
- Automation backlog: convert unchecked items to GitHub issues tagged `qa`.

_Next steps:_ Generate actual unit/widget tests per section 1, integrate into CI, and set calendar reminder for manual regression one week prior to launch.
