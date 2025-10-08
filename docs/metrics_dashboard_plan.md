# Success Metrics & Dashboard Blueprint

_Last updated: 2025-10-03_

## 1. KPI Overview
- **Activation:** first 3 completed sessions, first backup, onboarding completion.
- **Engagement:** D1/D7/D30 retention, weekly active timers, average focused minutes per user.
- **Reliability:** Crash-free sessions, background timer completion rate, backup success ratio.
- **Revenue:** Trial-to-paid conversion, renewal rate (RevenueCat), ARPU.

## 2. Event/Parameter Mapping
| KPI | Event | Parameters |
| --- | --- | --- |
| Activation | `session_start`, `session_end` | `mode`, `elapsed_sec`, `plan_segments` |
| Backup adoption | `backup_trigger` | `action`, `provider`, `bytes` |
| Onboarding completion | `onboarding_complete` (todo) | `variant`, `duration_sec` |
| Premium conversion | RevenueCat webhooks / `paywall_purchase` | `variant`, `product`, `price` |
| Retention | Firebase Analytics cohorts (auto) | n/a |
| Reliability | `backup_failure`, Crashlytics non-fatal tags | `action`, `error` |

## 3. Dashboard Stack (Draft)
- **Firebase Analytics:** primary event dashboards (Activation, Engagement). Create custom funnels for onboarding and backup.
- **BigQuery export (optional post-MVP):** raw events for retention cohorts and deeper segmentation.
- **RevenueCat Overview:** subscription revenue widgets (MRR, churn, renewals).
- **Crashlytics:** stability board with alerts on crash-free sessions < 99.8%.
- **Google Sheets (stopgap):** manual aggregation for backup success until BigQuery is enabled.

## 4. Alerting Targets
- Crash-free sessions < 99.8% for 24h → Slack #alerts.
- Backup failure rate > 2% daily → create incident ticket.
- RevenueCat grace-period users > 5% of active subs → run billing health check.

## 5. Implementation Tasks
1. Define Firebase Analytics audiences + custom dimensions (`mode`, `segment_type`).
2. Configure RevenueCat → Slack webhook for renewal/grace-period events.
3. Automate daily export of backup success ratios using Cloud Function (todo).
4. Update privacy policy once telemetry toggle UI ships.

_Next steps:_ Build initial Firebase dashboard with above widgets, document query links, and embed snapshots in weekly product review notes.
