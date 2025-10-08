# Life App Manual Test Matrix (v1.0)

> Use this checklist before each milestone release. Unless otherwise stated, run on both iOS (latest + n-1) and Android (latest + n-1) using production-like Firebase & RevenueCat configs.

## 1. Core Timer Flows

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| T-01 | Focus timer basic run | App fresh launch, default presets | Start focus timer, let first session end naturally | Segment auto-advances to break, notification + haptic fire, session logged locally |
| T-02 | Pause & resume | T-01 midway | Pause, wait 10s, resume | Remaining time preserved, notification rescheduled, timer foreground notification text updates |
| T-03 | Skip segment | Running focus cycle | Tap *Skip* during break | Next focus segment starts with correct duration, analytics `segment_skip` recorded |
| T-04 | Sleep smart alarm window | Sleep plan with smart window set (e.g., 30 min, 5 min interval) | Start sleep timer, leave app backgrounded | Gentle notifications fire every interval inside window, final notification uses full-screen intent |
| T-05 | App termination recovery | Timer running | Force close app (task switcher), relaunch after 15s | Timer restores state, countdown correct, audio resumes if enabled |

## 2. Background Reliability & Permissions

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| B-01 | Android exact alarm permission flow | Device on Android 14+ with permission revoked | Trigger sleep smart alarm | Permission banner shown, deep link opens system page, on approval smart alarm scheduling succeeds |
| B-02 | Android foreground service persistence | Timer running on Android 13+ | Background for 1h, observe OS system tray | Foreground notification stays visible, timer accuracy within ±3s |
| B-03 | iOS BG refresh hook | iOS 15+ physical device | Start timer, lock device for 20 min | BGTask fires (inspect logs), notifications remain scheduled |
| B-04 | DND guidance | Device DND disabled | Enable Focus timer sound & DND toggle | Permission prompt explains rationale, link opens system settings |

## 3. Data Resilience (Offline-First)

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| D-01 | Offline usage | Enable airplane mode | Complete focus + rest cycle | App fully functional offline, sessions stored locally |
| D-02 | Light sync merge | Two devices logged in same account | Run timer on device A, go online; open device B | Daily totals merge without duplication, presets sync |
| D-03 | Backup / restore | Create backup to Drive/iCloud | Reset app (delete & reinstall), restore archive | All sessions/routines/settings restored, last backup timestamp updated |
| D-04 | Corrupted backup guard | Modify backup (simulate corruption) | Attempt restore | Operation aborted with error message, local DB unchanged |

## 4. Subscription & Paywall

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| S-01 | Offerings load | RevenueCat sandbox configured | Open paywall | Current offering displayed, analytics `paywall_view` variant tagged |
| S-02 | Purchase flow | Sandbox tester logged out | Buy monthly SKU | Purchase succeeds, entitlement unlocks premium UI, RevenueCat restores across devices |
| S-03 | Grace period | Expire sandbox subscription | Open app | Grace notice shown with expiration date, premium remains active until grace end |
| S-04 | Unsupported platform paywall | macOS/Windows build | Open paywall | Static message “Purchases are only supported on iOS and Android builds.”, no spinner |

## 5. Analytics, Telemetry & Privacy

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| A-01 | Consent toggle | App default telemetry off | Enable analytics in settings (once implemented) | `AnalyticsService.updateConsent` invoked, Firebase events appear |
| A-02 | Crash capture opt-out | Telemetry disabled | Force crash via debug menu | Crashlytics does not log event |
| A-03 | Privacy disclosure | Account → Data usage card | Review content | Copy matches docs/privacy policy, links open successfully |

## 6. Localization & Accessibility

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| L-01 | Locale switching | Device set to Korean | Navigate onboarding, timer, paywall | All strings localized, no layout clipping |
| L-02 | English locale | Device set to English | Repeat L-01 | English copy matches spec |
| L-03 | Dynamic type | iOS with large accessibility text | Review timer & account screens | UI scrollable, text not truncated |
| L-04 | RTL smoke test | Android emulator Arabic locale | Open key screens | Layout mirrors appropriately, icons remain logical |
| L-05 | Screen reader labels | VoiceOver/TalkBack enabled | Navigate onboarding, timer controls | Controls announce clear labels, timer progress updates via live region |

## 7. Performance & Battery (Spot Checks)

| ID | Scenario | Preconditions | Steps | Expected |
| -- | -------- | ------------- | ----- | -------- |
| P-01 | Cold start time | Release build | Launch after reboot | Splash → home within target (<2.5s) |
| P-02 | Memory footprint | Run 4h focus cycle | Inspect dev tools | App stays <200MB, no leaks |
| P-03 | Battery drain | 1h background timer with audio | Measure battery delta | ≤2% drain per hour target |

## Execution Log

Maintain a copy of this matrix per release in `/docs/testing/runs/` with dates, devices, OS versions, tester initials, and pass/fail notes.
