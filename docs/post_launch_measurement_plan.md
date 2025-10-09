# Post-Launch Measurement & Iteration Plan

Supports Checklist **15. Post-Launch Measurement & Iteration**.

## 1. Design Sprint for Immersive UI
- **Objective**: deliver a prototype for immersive emotional feedback (animations, adaptive sound cues) that can ship during the first post-launch heartbeat.
- **Inputs**: competitor audit, existing user feedback, analytics (session length, churn reasons).
- **Timeline & Roles**:
  | Day | Focus | Facilitators | Participants |
  |-----|-------|--------------|--------------|
  | Day 0 (Prep) | Synthesize insights, recruit interviewees, gather motion/sound references | PM + Lead Designer | Research ops, audio designer |
  | Day 1 | Map problem + lightning talks | PM (facilitator) | Design, eng, audio, retention analyst |
  | Day 2 | Sketch & decide (Crazy 8s, heat map voting) | Lead Designer | Same as Day 1 |
  | Day 3 | Prototype in Figma/ProtoPie + audio samples | Lead Designer + Audio Designer | Motion specialist, eng pairing |
  | Day 4 | User testing (5 remote sessions) + synthesis | UX Researcher | Note takers, PM |
  | Day 5 (Playback) | Prioritize scope, define engineering slices | PM + Tech Lead | Cross-functional team |
- **Activities**:
  1. Discovery interviews with 5–7 users per persona.
  2. Co-creation workshop with design/product/engineering to sketch ideas.
  3. High-fidelity prototype with motion specs (Lottie/After Effects) and audio guidelines (loop length, loudness targets).
  4. Usability validation (remote testing) before handoff.
- **Deliverables**:
  - Design spec in Figma (motion storyboard + UI states).
  - Audio asset brief (format, sample rate, licensing notes).
  - Engineering feasibility memo with performance/battery considerations and phased backlog (MVP, polish, stretch).
  - Success metrics definition (target uplift in session completion rate, CSAT change) to feed into KPI tracking.

## 2. Backup Reminder & Preset Recommendation A/B Tests
- **Hypothesis**: targeted reminders and context-aware preset suggestions increase backup completion and routine adherence.
- **Experiment Skeleton**:
  | Variant | Description | Primary KPI | Guardrail |
  |---------|-------------|-------------|-----------|
  | A — Control | Existing experience | Backup completion rate | Reminder opt-out rate |
  | B — Reminder | Weekly in-app reminder banner + push | Backup completion rate | Notification opt-out |
  | C — Recommendation | Contextual preset suggestion after routine streaks | Preset adoption rate | Session churn |
  | D — Combined | Reminder + recommendation | Backup completion + preset adoption | Support ticket volume |
- **Metrics & Instrumentation**:
  - Primary KPIs: `backup_completion_rate`, `preset_accept_rate`, `routine_streak_gain`.
  - Secondary: notification opt-out, reminder dismissals, preset skips, retention delta.
  - Instrument new events: `backup_reminder_shown`, `backup_reminder_dismissed`, `preset_suggested`, `preset_applied`, `preset_dismissed`.
- **Sample Size & Duration**:
  - Baseline: 18% weekly backup rate, 12% preset adoption.
  - Minimum detectable lift: +5 p.p. backup, +4 p.p. preset.
  - Required n per variant ≈ 2,400 weekly actives (power 0.8, α=0.05). Use `analytics/ab_test_sizer.xlsx` for exact numbers.
  - Run until either 4 weeks elapsed or each variant accumulates ≥ n completions.
- **Experiment Runbook**:
  1. Create remote-config keys `ab_backup_variant` (A–D) and `ab_preset_variant` (A/C/D).
  2. Update `backup_banner_service` and `preset_recommendation_provider` to respect variant assignment.
  3. Publish analyst dashboard (Looker/Metabase) with blended funnel and guardrails.
  4. Hold weekly check-ins; halt test if guardrail breached (>5% opt-outs or support spike).
- **Deliverables**:
  - Experiment brief stored in `docs/analytics/backup_presets_ab_test.md`.
  - Instrumentation checklist + JIRA tickets for client/backend work.
  - Decision template capturing launch/rollback criteria.

## 3. Advanced Reports & Visualization Requirements
- **Data Scope**:
  - Daily rollups: focus/rest/workout/sleep minutes, completion %, streak state.
  - Weekly/monthly aggregates with goal comparisons and moving averages (7/30-day windows).
  - Correlation panels: timer vs mood (journal), backup cadence vs streak retention.
  - Export options: PDF (sharing), CSV (data export) with localization-aware formatting.
- **Pipeline Requirements**:
  - Extend `DailySummaryLocal` aggregation job to emit weekly/monthly collections.
  - Add BigQuery scheduled function (or server cron) to enrich with Remote Config cohort tags.
  - Provide REST endpoint `/reports/{period}` returning normalized DTOs (hydrated with goals).
- **Flutter Visualization Componentry**:
  - `ReportsOverviewChart` (stacked bar) using `syncfusion_flutter_charts` or custom painter.
  - `GoalComparisonCard` with sparkline + delta indicator.
  - `CorrelationHeatmap` for mood vs sleep/focus, including accessibility color palettes.
  - `ExportButtonRow` abstracted for PDF/CSV triggers, with offline-ready state handling.
- **Security & Privacy**:
  - Ensure exports respect PII redaction, rely on existing encryption for device-local storage.
  - Document retention policy alignment with `docs/privacy_data_retention.md`.
- **Deliverables**:
  - Requirements spec `docs/reports/advanced_reports_spec.md` (create during sprint).
  - Figma mocks with responsive breakpoints and dark mode treatment.
  - Implementation backlog: API tickets, widget implementation, QA test matrix.

## 4. Watch / Shortcuts Proof of Concept
- **Scope**:
  - Shortcut intents: start/stop focus timer, add quick routine note, mark session complete.
  - Apple Watch: minimal watch app + complication showing timer countdown and upcoming wake window.
  - Wear OS: tile + complication that mirrors countdown and quick actions.
- **PoC Plan**:
  |- Step | Description | Owner |
  |------|-------------|-------|
  | 1 | Implement `TimerIntentStart` / `TimerIntentStop` using the `appshortcuts` Flutter package, expose via `@AppIntent` annotation | Flutter dev |
  | 2 | Add background handler to route intents to `TimerController` (validate start/stop works while app paused) | Flutter dev |
  | 3 | Scaffold watchOS target with `flutter create --platforms=watchos`, render countdown + quick reset | iOS dev |
  | 4 | Spike Wear OS tile via `wear` package or native module, show same countdown | Android dev |
  | 5 | Instrument battery usage measurement (Energy Log on watchOS, Battery Historian on Wear OS) | QA |
  | 6 | Document limitations, open issues (e.g., Shortcuts background execution window) | PM |
- **Telemetry & Logging**:
  - Events: `shortcut_invoked`, `shortcut_failed`, `wearable_tile_tap`, `wearable_complication_refresh`.
  - Add crash/analytic hooks to track failure points during PoC.
- **Deliverables**:
  - Demo video + build artifacts (`runs/poc/watch_shortcuts/`).
  - Technical report summarizing APIs used, open risks, next iteration tasks.

## 5. Tracking & Governance
- Weekly sync to review ongoing experiments, design progress, and analytics impact.
- Update `docs/data_review_cadence.md` and `post_launch_roadmap.md` with milestones once each deliverable is ready.

Use this plan as the source of truth when spinning up sprint tickets for Checklist #15.
