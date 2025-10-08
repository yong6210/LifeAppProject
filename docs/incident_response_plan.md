# Incident Response Plan (v1.0)

## 1. Objectives
- Detect, triage, and resolve production incidents (crashes, data loss, billing issues) quickly.
- Communicate clearly with users and stakeholders.
- Capture learnings for prevention.

## 2. Incident Types & Severity
| Severity | Definition | Examples | Initial Owner |
| -------- | ---------- | -------- | ------------- |
| SEV-0 | Catastrophic outage; majority of users impacted. | App crashes on launch after update, subscription service down globally. | Engineering on-call + Lead. |
| SEV-1 | Major functionality degraded; workaround exists. | Backup restore failing for one platform, payments delayed. | Engineering on-call. |
| SEV-2 | Minor impact or isolated crash; monitored. | Single feature regression, analytics outage. | Feature owner. |

## 3. On-call & Alerting
- **Schedule**: Weekly rotation shared between mobile engineers.
- **Alert Sources**:
  - Crashlytics alert groups (`life-app-sev0`, `life-app-sev1`).
  - RevenueCat webhooks (billing failures) → Slack `#alerts-revenue`.
  - Firebase Performance thresholds (startup > 3s, ANR > 0.5%).
- **Escalation**:
  1. On-call acknowledges within 15 minutes.
  2. If no response, alert backup engineer + PM.
  3. For SEV-0, notify leadership (CEO/COO) immediately.

## 4. Response Workflow
1. **Detect & Triage**
   - Confirm alert validity (duplicate? false positive?).
   - Assign severity & incident commander (IC).
2. **Stabilize**
   - Mitigate: disable feature flag, roll back release, hotfix.
   - Communicate status in Slack `#incidents` using template.
3. **Communicate**
   - Internal bulletin (Slack) every 30 mins for SEV-0/1.
   - External message (email, Twitter, in-app banner) when user-facing.
4. **Resolution**
   - Confirm metrics back to normal.
   - Document timeline and root cause.
5. **Postmortem**
   - Create Notion doc within 2 days.
   - Include impact, fix, preventive actions.

## 5. Communication Templates
**Internal Slack (Initial)**
```
INCIDENT START
Severity: SEV-{level}
Summary: {issue}
Impact: {users/features affected}
Commander: {name}
Next update: {time}
```

**External Email / In-app Banner**
> We’re investigating an issue causing {impact}. Offline timers continue to work, and we’ll share updates at {link}. Thank you for your patience.

## 6. Tooling
- **Issue Tracking**: Create Jira ticket with `INCIDENT` label.
- **Monitoring**: Crashlytics dashboards, Firebase Performance, RevenueCat dashboards.
- **Rollback**: Maintain last-known-good builds (TestFlight/Play internal) for quick promotion.
- **Logging**: `server/revenuecat_webhook` logs via Cloud Logging.

## 7. Pre-release Checklist
- Run smoke tests before promotion (timer start/stop, backup, subscription flow).
- Ensure feature flags allow remote disable of risky features (sleep smart alarm, weekly backup).
- Update on-call schedule and share in Slack each Monday.

## 8. Post-incident Review
- Review backlog for preventive tasks (tests, monitoring, feature flagging).
- Evaluate communication effectiveness.
- Update incident metrics dashboard (time to detect, acknowledge, resolve).

## 9. Document Maintenance
- Review and update this plan quarterly or after any SEV-0/1 incident.
- Store template copies in the ops Notion space.
