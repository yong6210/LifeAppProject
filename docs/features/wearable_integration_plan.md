# Wearable Integration Plan

Covers Checklist **21. Wearable Integration**.

## 1. Integration Goals
- Import sleep stages, heart rate, HRV, and basic activity data from Apple HealthKit and Google Fit so the app can enrich sleep/focus analytics.
- Provide a seamless permission flow that respects privacy and explains value.
- Ensure QA coverage on Apple Watch and Wear OS devices.

### Permission & Onboarding UX (New)
- **Entry points**: Sleep dashboard CTA, Account ▸ Data Integrations, onboarding “connect your wearable” step.
- **Copy guidelines** (localized into `intl_en.arb` / `intl_ko.arb` when implemented):
  - *Headline*: “연결된 기기로 더 정확한 수면 리포트를 받아보세요” / “Connect your wearable for richer insights”.
  - *Value bullets*:
    1. “수면 단계와 HRV 변화를 자동으로 불러옵니다.” / “Automatically import sleep stages and HRV trends.”
    2. “집중/휴식 루틴에 맞춘 맞춤 추천을 제공합니다.” / “Get routine recommendations tailored to your day.”
    3. “데이터는 암호화되어 저장되며 언제든 연결 해제할 수 있습니다.” / “Data stays encrypted and you can disconnect anytime.”
  - *Permission prompt microcopy*:
    - HealthKit usage string: “수면 분석과 심박 정보를 불러와 맞춤 리포트를 제공합니다.”
    - Google Fit scope dialog helper text: “Google Fit에서 수면·심박·활동 데이터를 읽어 Life App 리포트를 향상시킵니다.”
- **Flow**:
  1. Inline value screen with toggle chips for “Sleep”, “Heart”, “Activity” scopes (all default on).
  2. Tap “Continue” → native permission dialogs (HealthKit/Google Fit). Provide “Learn more” link to privacy policy section.
  3. Success state summarises enabled scopes + “Manage permissions” shortcut.
  4. Failure/denied state offers retry + “Continue without wearable” option.
- **Accessibility**: Ensure captions and VoiceOver labels explain each scope; minimum contrast ratio 4.5:1. Motion sparingly.

## 2. Scope Breakdown
1. **Product & UX**
   - Define use cases (e.g., richer sleep insights, smarter routine recommendations, anomaly alerts).
   - Produce permission/onboarding mockups (value proposition, data usage, opt-out).
2. **iOS HealthKit Pipeline**
  - Create HealthKit capability, entitlements, and Info.plist usage descriptions.
  - Implement queries for `HKCategoryTypeIdentifier.sleepAnalysis`, `HKQuantityTypeIdentifier.heartRate`, `HKQuantityTypeIdentifier.heartRateVariabilitySDNN`.
  - Set up background delivery or periodic sync with throttling.
3. **Android Google Fit Pipeline**
   - Register OAuth client, configure scopes (sleep, heartrate, activity).
   - Implement `GoogleSignIn` + `Fitness.getHistoryClient` flows.
   - Handle token refresh, offline caching, and error states.
4. **Data Modeling & Sync**
   - Map wearable samples to existing analytics models; decide storage (local vs remote).
   - Determine time-window aggregation (e.g., nightly summary) and merge rules when data conflicts with in-app logs.
5. **Privacy & Policy Updates**
   - Update privacy policy with new data types and retention.
   - Prepare App Store/Play Store review notes referencing HealthKit/Fit usage.
6. **QA & Monitoring**
   - Device matrix: Apple Watch (Series 6+), Wear OS (Pixel Watch), plus phones (iOS/Android).
   - Regression tests for permission denial, revocation, limited data availability.
   - Monitoring alerts if wearable sync fails.

### API Sketch (NEW)
- **Fetch job**  
  - Entry point: `WearableSyncService.sync({required WearableSource source})`.  
  - Schedules platform-specific fetch (`HealthKitSyncDelegate`, `GoogleFitSyncDelegate`).  
  - Merges results into `WearableMetricsStore` (Isar collection `WearableMetric` keyed by `date + metricType`).
- **Data shape**  
  ```dart
  enum WearableMetricType { sleepStage, heartRate, hrv, steps }

  class WearableMetric {
    final DateTime start;
    final DateTime end;
    final WearableMetricType type;
    final double value;
    final Map<String, dynamic> metadata; // sourceId, confidence, etc.
  }
  ```
- **Merge rules**  
  - Convert all timestamps to UTC before persistence.  
  - If multiple devices supply the same metric within a 5분 window, prefer the highest confidence (`metadata['confidence']`).  
  - When in-app sleep logs overlap with wearable sleep stages, keep both but mark derived recommendations to favour wearable data (flag `sourcePriority`).
- **Analytics integration**  
  - `SleepInsightsRepository` consumes aggregated wearable metrics to render snore vs. HRV deltas.  
  - `RoutineRecommendationEngine` receives `WearableSnapshot` combining previous-night HRV + focus streak to adjust suggested routines.
- **Backfill**  
  - First sync pulls the last 14 days per metric (HealthKit anchored object queries, Google Fit History API). Subsequent syncs fetch incremental deltas.
- **Error handling**  
  - Dedicate `WearableSyncFailure` model: contains scope, platform, error code, retryAfter.  
  - Surface non-blocking toasts + Settings banner for revoked permissions.

## 3. Checklist
- [x] UX copy and permission screens approved.
- [x] Create Flutter-side mock integration surface (`WearableRepository`) and insights UI to prepare for real HealthKit/Google Fit wiring.
- [ ] HealthKit entitlements, queries, and background delivery in place.
- [ ] Google Fit OAuth client configured and tested.
- [ ] Data pipeline persists wearable metrics and feeds analytics/recommendations.
- [ ] Privacy documentation and store review notes updated.
- [ ] QA pass on physical wearables; automated regression scripts updated.

## 4. Timeline Suggestions
| Phase | Owner | Duration |
|-------|-------|----------|
| UX + legal prep | PM/UX | 1 week |
| HealthKit implementation (live data) | iOS dev | 1–2 weeks |
| Google Fit implementation (live data) | Android dev | 1–2 weeks |
| Data integration & analytics updates | Backend/Mobile | 1–2 weeks |
| QA & monitoring setup | QA/DevOps | 1 week |

## 5. Risks
- **Permission fatigue**: ensure clear value messaging and incremental onboarding.
- **Incomplete data**: provide fallbacks when wearables are not worn; avoid breaking analytics.
- **Review rejection**: double-check HealthKit usage description (only read access, no medical claims).
- **Maintenance overhead**: schedule periodic API reviews as Apple/Google update requirements.

Document owners should update progress here and link to implementation PRs when each checklist item is complete.
