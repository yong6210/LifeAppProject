# Analytics Instrumentation Plan (v1.0)

## 1. Goals
- Track feature adoption (backups, timer usage, premium conversion) to drive roadmap decisions.
- Provide high signal metrics for the weekly data review (`docs/data_review_cadence.md`).
- Enable experiment evaluation (paywall, onboarding variants).

## 2. Event Vocabulary
| Event | When | Properties |
| ----- | ---- | ---------- |
| `session_start` | Timer begins (focus/rest/workout/sleep). | `mode`, `preset_id`, `sound_enabled`, `streak_before`. |
| `session_end` | Timer finishes or user stops. | `mode`, `duration_sec`, `segments`, `completed`. |
| `segment_complete` | Timer segment transitions. | `mode`, `segment_id`, `segment_label`, `duration_sec`. |
| `backup_trigger` | Backup or restore initiated/completed. | `action` (`backup`/`restore`), `provider`, `bytes`, `status`. |
| `backup_reminder_shown` | Reminder notification shown. | `days_since_last_backup`, `has_backup`. |
| `backup_banner_tap` / `backup_banner_dismiss` | In-app banner CTA usage. | `streak_weeks`, `has_recent_backup`. |
| `backup_streak_progress` | Streak increments. | `streak_weeks`. |
| `paywall_view` | Paywall presented. | `variant`, `has_offer`, `source`. |
| `paywall_purchase` / `paywall_purchase_error` | Purchase success/failure. | `variant`, `product`, `error`. |
| `premium_gate` | User hits premium-only feature. | `feature`, `entitled`. |
| `onboarding_step_complete` | User finishes an onboarding card. | `step_id`, `variant`. |
| `reminder_permission_prompt` | Exact alarm/notification prompt shown. | `type`, `state_before`. |
| `diagnostics_export` | Timer diagnostics CSV exported. | `count`, `skew_ms_avg`. |

## 3. User Properties / Attributes
- `beta_cohort` (remote config flag).
- `paywall_variant` (RevenueCat → Firebase user property).
- `has_backup` (true if `Settings.lastBackupAt != null`).
- `premium_status` (`free`, `trial`, `active`, `grace`, `expired`).

## 4. Instrumentation Matrix
| Area | Owner | Implementation Notes |
| ---- | ----- | -------------------- |
| Timer events | Engineering | Already instrumented (`TimerController`). Audit event payloads to ensure `mode` + `duration`. |
| Backup reminders | Engineering | Added in `main.dart` and account banner. Verify analytics guard against null data. |
| Paywall | Growth | Confirm `source` values (`home_cta`, `backup_banner`, etc.). |
| Onboarding | Product | `OnboardingPage` reports `onboarding_variant` from remote config. |
| Notification permission prompts | Engineering | Hook into `TimerPermissionService`. |

## 5. Data Flow
- **Mobile App → Firebase Analytics** via `AnalyticsService.logEvent`.
- **RevenueCat Webhooks → Firestore** (see `docs/revenuecat_webhook_plan.md`).
- **BigQuery Export**: nightly export of Firebase/RevenueCat events for Looker dashboards.

## 6. QA & Validation
- Enable debug view (`adb shell setprop debug.firebase.analytics.app com.ymcompany.lifeapp`) to live-inspect events.
- Use unit/widget tests to ensure instrumentation covers new features (e.g., backup banner, reminders).
- Pre-release checklist: run through manual test matrix, confirm events appear in GA DebugView.

## 7. Reporting
- Weekly analytics sync references:
  - `Backup` dashboard (backup_trigger success %, streak growth).
  - `Subscription` dashboard (paywall_view, purchase conversion).
  - `Timer` dashboard (session_start/end counts, retention proxies).
- Monthly deep dive uses Looker chart snapshots exporting from BigQuery.

## 8. Governance
- PM approves new event names to maintain consistency.
- Engineering updates this doc when introducing/removing events.
- Keep events ≤ 25 per session to stay within Firebase limits; prefer parameters over new event names when feasible.
