# Battery Instrumentation Plan (v1.0)

## Objective
Confirm the timer engine meets the target of ≤2% battery drop per hour session (baseline device battery capacity: ~4000 mAh) across Android and iOS using representative devices.

## Test Matrix
| Platform | Device | OS | Mode | Notes |
| -------- | ------ | -- | ---- | ----- |
| Android | Pixel 7 | Android 14 | Focus 60 min, audio off | Baseline.
| Android | Pixel 7 | Android 14 | Sleep 60 min, mixer on | Worst case audio + notifications.
| iOS | iPhone 14 | iOS 17 | Focus 60 min, audio off | Baseline.
| iOS | iPhone 14 | iOS 17 | Sleep 60 min, mixer on | Worst case.

## Procedure
1. Charge device to 100% (disable battery saver, enable airplane mode if allowed for baseline test; keep Wi-Fi on for sync tests).
2. Reset stats:
   - Android: `adb shell dumpsys batterystats --reset`.
   - iOS: Settings ▸ Battery ▸ reset usage stats (or note baseline percentage).
3. Start timer session; log start time.
4. Keep device awake (screen dimmed) with timer running in background/foreground as appropriate.
5. After 60 minutes, capture metrics:
   - **Android**: `adb shell dumpsys batterystats --charged` (look for `% battery drop` and app UID consumption).
   - **iOS**: Xcode → Devices & Simulators → Energy log; record average energy impact, battery % change from Settings.
6. Export diagnostics (`Account ▸ Timer accuracy ▸ Export CSV`) and attach to run log.
7. Record findings in `docs/testing/runs/<date>_battery.md` using template below.

## Run Log Template
```
# Battery Test – <YYYY-MM-DD>

## Android Pixel 7 – Focus mode, audio off
- Start %, End %, Drop %.
- Energy impact (adb dumpsys): ...
- Notes: (notifications, background usage, anomalies)

## Android Pixel 7 – Sleep mode, mixer on
- ...

## iPhone 14 – Focus
- ...

## iPhone 14 – Sleep
- ...

## Summary
- Max observed drop: ...
- Pass/Fail vs ≤2% target: ...
- Follow-up actions: ...
```

## Alert Threshold
- Flag result if any scenario exceeds 2.0% drop per hour.
- For repeated failures, open Jira ticket with device logs and assign to timer team.

## Responsible Roles
- QA lead executes tests before each milestone release.
- Engineering reviews deviations and proposes optimizations (e.g., adjust workmanager intervals, audio mixing).

Update this plan as new devices or modes are added (e.g., ambient focus mode, wearables).
