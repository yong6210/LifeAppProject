# Backlog Grooming Runbook (Beta → Launch)

## 1. Cadence & Participants
- **Meeting**: Bi-weekly, 45 minutes, held Tuesdays at 10:00 AM KST (one day before sprint planning).
- **Attendees**: PM (moderator), Engineering lead (or on-call), Design lead, Growth/Marketing representative, Support lead.
- **Slack reminder**: Scheduled in `#product` channel 24 hours prior with link to agenda.

## 2. Pre-meeting Inputs (due by Monday 18:00)
- **Support**: Top support themes (ticket counts, impacts) via Notion intake form.
- **Analytics**: KPI deltas and experiment outcomes from weekly data review (`docs/data_review_cadence.md`) § Weekly sync.
- **Market/Research**: Upcoming user interviews, partner requests, community feedback snapshots.
- **Engineering**: Tech debt/maintenance proposals (performance, dependency upgrades, tooling).

PM consolidates the submissions into the `Backlog Grooming Agenda` (Notion board filtered to `Needs grooming` status).

## 3. Meeting Flow
1. **Review inputs** (10 min)
   - Quick recap of KPI changes; highlight urgent support issues or regulatory deadlines.
2. **Discuss candidate items** (20 min)
   - For each backlog candidate provide: context, data source, dependencies, and proposed impact.
   - Engineering shares feasibility/estimates; design notes research needs.
3. **Prioritize & Next Steps** (10 min)
   - Apply ICE/RICE scoring: Impact, Confidence, Effort (score updated in Notion).
   - Move tasks into `Now` (next sprint), `Next`, or `Later` columns.
4. **Action recap** (5 min)
   - Document decisions in Notion summary.
   - Post Slack recap with top items and owners.

## 4. Artifact Updates
- Move committed items into the upcoming sprint board (Notion → `Sprint N` view).
- Convert open questions into JIRA/Notion tasks (tagged `support`, `analytics`, `research`, `tech-debt`).
- Update roadmap entries (see `docs/post_launch_roadmap.md`) if prioritization changes.

## 5. Follow-up Tasks
- PM ensures new tasks have clear acceptance criteria and analytics instrumentation requirements.
- Engineering flags tasks requiring spike/POC; schedule discovery tickets.
- Support closes the loop with users when items are accepted into roadmap.

## 6. Quarterly Review
- Assess grooming effectiveness (e.g., % tasks with clear owners, average time from intake to decision).
- Adjust cadence or attendee list as team size evolves.
