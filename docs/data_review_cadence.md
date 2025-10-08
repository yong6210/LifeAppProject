# Data Review Cadence (v1.0)

## Objectives
- Ensure subscription, engagement, and reliability KPIs are reviewed regularly.
- Align PM, engineering, and growth on trends and experiment outcomes.

## Weekly Analytics Sync (30 min)
**Attendees**: PM, Engineering lead, Growth/Marketing, Support lead.
**Inputs** (auto-generated dashboards in Looker/Firebase):
1. **Activation & Retention**
   - D1 / D7 / D30 retention.
   - Routine completion rate.
2. **Revenue**
   - Trial activations, conversion %, churn (RevenueCat).
   - MRR, cancel reasons (webhook-derived).
3. **Backup Adoption**
   - # backups/week, restore success %, export diagnostics count.
4. **Reliability**
   - Crash-free sessions, ANR %, timer skew alerts.
5. **Feedback**
   - Top support themes, beta feedback summary.

### Meeting Flow
1. Review dashboard snapshots (5 min).
2. Discuss deviations vs goals (10 min).
3. Decide on top 2 follow-up actions (10 min).
4. Assign owners / due dates (5 min).

## Monthly Deep Dive (60 min)
**Attendees**: Leadership, PM, Engineering, Design.
**Agenda**:
1. Trend analysis (MoM, QoQ) for key metrics.
2. Experiment readouts (paywall A/B, onboarding variants).
3. Roadmap adjustments (inform `docs/post_launch_roadmap.md`).
4. Compliance/privacy check-in (handoff to audit schedule).

## Tooling & Automation
- Export Firebase Analytics + RevenueCat data to BigQuery nightly.
- Maintain Looker dashboards (`Dashboards/Weekly Insights`, `Revenue Overview`).
- Use Notion table `Data Review Log` to capture decisions + tasks.

## Roles & Responsibilities
- **PM**: Prepare dashboards, facilitate meeting, update roadmap.
- **Engineering**: Investigate anomalies, provide technical context.
- **Growth**: Propose experiments, monitor conversion funnel.
- **Support**: Surface qualitative insights from tickets.

## Templates
- Notion meeting notes template with sections: Metrics, Discussion, Actions.
- Slack summary message after each weekly sync (auto-reminder via workflow).

Review cadence each quarter to adjust metrics or meeting frequency.
