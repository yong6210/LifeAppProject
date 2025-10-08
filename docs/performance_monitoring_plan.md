# Performance & Battery Monitoring Plan (v1.0)

## 1. Timer Alarm Accuracy Validation

1. **Instrumentation**: `TimerController` emits `timer_accuracy_sample` analytics events with segment skew in milliseconds and stores the last 50 readings locally (Account ▸ Timer accuracy card).
2. **Method**:
   - Run focus/rest/sleep cycles on Android & iOS physical devices.
   - Export analytics (BigQuery/Firebase) filtering `timer_accuracy_sample` for `skew_ms` outside ±60000.
   - Complement with native logs (Android `adb shell dumpsys alarm`, iOS Xcode console) to inspect scheduled vs delivered times.
3. **Acceptance**: 95% of samples within ±60,000 ms, max within ±120,000 ms (accounts for OS batching when device idle).

## 2. Smart Alarm Window Check

- Record `timer_accuracy_sample` near smart alarm window end and cross-reference with scheduled notifications from `scheduleSmartSleepAlarmWindow`.
- Use manual test cases B-01/B-03 in `docs/testing/manual_test_matrix.md`.

## 3. Battery Impact Measurement

1. **Android**:
   - Reset stats: `adb shell dumpsys batterystats --reset`.
   - Run 1h timer session with audio and foreground service active.
   - Collect stats: `adb shell dumpsys batterystats` → `Battery History` and `Uid` consumption; `adb shell dumpsys batterystats --charged` for summary.
   - Calculate % drop (should be ≤2%).
2. **iOS**:
   - Use Xcode Energy Log with 1h background timer.
   - Capture `Energy Impact` metric and battery % from Settings → Battery.
3. **Reporting**: Store measurements under `docs/testing/runs/<date>/battery.md` with devices, OS, build hash. Use the in-app diagnostics card to export a CSV of skew samples (Account ▸ Timer accuracy ▸ Export CSV) and attach it to the run log alongside battery readings.

## 4. Baseline Performance Metrics

- **Cold start** (target < 2.5s P90, alert if P95 > 3.0s)
  - Android: `flutter run --trace-startup` or Firebase Performance startup trace.
  - iOS: Xcode Instruments Time Profiler.
- **Runtime memory** (target < 250 MB on modern devices, alert if > 300 MB sustained)
  - Android: `adb shell dumpsys meminfo com.ymcompany.lifeapp` after 30 min usage.
  - iOS: Xcode memory graph snapshot.
- **CPU load** (target < 50% sustained during active timer, alert if > 70% for > 60s)
  - Android Studio Profiler, Xcode CPU profiler.

## 5. Automation Hooks (Future)

- Integrate `timer_accuracy_sample` export into weekly Looker/Firebase dashboards.
- Add CI job to parse `Performance` log output from integration tests (when device farm available).

## 6. Alerting & Dashboards
- **Firebase Performance Alerts**
  - Startup trace > 3.0s P95 → email + Slack `#alerts-performance`.
  - Network call slowdown (> 1s) for sync endpoint → review Firestore indexing.
- **Crashlytics**
  - Monitor ANR/Fatal sessions; trigger SEV-1 if ANR > 0.5%.
- **Weekly Review**
  - QA lead updates `docs/testing/runs/yyyy-mm-dd_performance.md` with latest measurements.
  - Product meeting includes performance KPI slide (startup, memory, CPU trend).

Maintain measurement evidence alongside release notes to demonstrate compliance with checklist targets.
