# Backlog Grooming Plan (v1.0)

## Purpose
Maintain a prioritized, actionable backlog that reflects user needs, analytics insights, and technical health.

## Cadence
- **Bi-weekly grooming session** (45 minutes) before sprint planning.
- **Inputs due 24 hours before meeting**.

## Inputs & Sources
1. **Support** – Top 5 ticket themes, customer pain points (from `docs/support_playbook.md` tracker).
2. **Analytics/Data** – KPI deltas, experiment results (from `docs/data_review_cadence.md`).
3. **Product Research** – Upcoming user interviews, community feedback.
4. **Engineering** – Tech debt, performance issues, dependency updates.

## Pre-meeting Prep
- PM compiles `Grooming Agenda` doc with candidate items (Notion board filtered by status = “Needs grooming”).
- Each item includes description, impact, data source, dependencies.
- Engineering reviews items for feasibility/estimates.

## Meeting Flow
1. **Review new inputs** (10 min).
2. **Discuss candidate items** (20 min): clarify requirement, scope, impact.
3. **Prioritize** (10 min): apply RICE/ICE scoring, assign to upcoming sprint or icebox.
4. **Action recap** (5 min): confirm owners, update backlog status.

## Backlog Structure
- **Now** – Committed for next sprint.
- **Next** – Ready but waiting for capacity.
- **Later** – Longer-term ideas; require validation.
- **Parked** – Archived items; revisit if assumptions change.

## Tooling
- Maintain shared Notion board (`Backlog - Life App`).
- Use labels: `support`, `analytics`, `research`, `tech-debt`, `regulatory`.
- Automate intake forms for support/analytics to push into backlog with metadata.

## Roles
- **PM**: Facilitates grooming, ensures decisions documented.
- **Engineering Lead**: Provides effort estimates, flags blockers.
- **Support & Analytics**: Present latest findings; advocate for user pain points.
- **Design**: Highlight UX debts, research insights.

## Post-meeting
- Update backlog statuses and scoring.
- Share summary in Slack `#product` channel with top decisions.
- Reflect updates in sprint planning doc.

Review grooming process quarterly to ensure alignment with team size and cadence.
