# Security Priorities & Competitive Feature Roadmap

This document consolidates work for Checklist **17. Security Priorities** and **20. Competitive Feature Expansion**.

## 1. Security & Privacy Enhancements
- **Immersive UI Feedback**: build on design sprint output; ensure animations/sounds comply with accessibility guidelines.
- **Personalized Wellness Guidance**: extend breathing/stretching libraries with metadata (difficulty, goals) and connect to user profile preferences.
  - **Content backlog**: 18 guided sessions (morning stretch, desk reset, evening unwind) per locale. Each script includes breath tempo (inhale/exhale counts), stretch duration, optional props.
  - **Metadata schema**: `{id, title_key, description_key, category, difficulty, goals[], duration_sec, requires_space, audio_asset, haptic_pattern}`.
  - **Recommendation logic**: tie presets to Settings ▸ Goals (e.g., “improve posture”), backup streak (prompt relax after backup), and time-of-day heuristics.
  - **In-app UX**: add “Guided Routines” tab under rest mode with preview cards, offline caching indicator, and progress tracking (completed count per week).
  - **Localization**: scripts and audio recorded in EN/KR, ensure accent-neutral voice talent, provide text captions for accessibility.
  - **Analytics**: track events `guided_routine_started`, `guided_routine_completed`, `guided_routine_favorite`, and feed into recommendation feedback loop.
- **Advanced Insights**: design weekly/monthly goal dashboards and anomaly alerts with proper data retention policies.
  - **KPIs**: weekly completion %, goal attainment delta, rolling 7/30-day averages, sleep vs focus correlation score.
  - **Data Model**: extend `DailySummaryLocal` with goal snapshot + variance; introduce `AnalyticsAggregate` collection for weekly/monthly rollups.
  - **Charts**: stacked bar for time distribution, goal vs actual line chart, anomalies table with contextual tips.
  - **Alerts**: rule engine triggers cards (“집중 시간이 목표보다 20% 낮습니다”) with actionable recommendations (start guided focus plan).
  - **Exports**: PDF summary with localized copy + CSV download per metric; enforce PII redaction on share.
  - **Governance**: retention aligned with privacy policy (90일 raw, 1년 aggregate), audit log for export actions.
- **Multi-Device Automation**: orchestrate integrations (Apple Watch, Wear OS, calendar, Shortcuts) under a single permission management module.
- **Community Features**: define privacy-first sharing rules (opt-in, moderation, reporting) before implementing preset sharing/challenges.
  - See `docs/features/community_challenges.md` for invite/challenge system plan (templates, privacy defaults, analytics).
  - MVP: private focus/rest challenges with invite token, local tracking, coach integration.
  - Future: backend sync, seasonal events, premium-only rewards.
- **Premium Value Boosters**: plan exclusive content (custom soundscapes, AI coach, diagnostic reports) and align with RevenueCat offerings.
  - Introduce coin economy (daily quests, streak rewards) and allow redemption for premium sound packs or time-limited passes.

### Checklist
- [x] Privacy impact assessment updated for each new data type/feature.
- [x] Threat modeling session held after major feature additions.
- [x] Audit logging & monitoring specs updated (especially for community interactions).

### Priority Action Items
| # | Priority | Immediate Actions | Owner | Target |
|---|----------|------------------|-------|--------|
| 1 | Immersive UI Feedback | Run micro-design sprint, catalog reusable animation components, schedule accessibility review | Design + Front-end | Week 1 |
| 2 | Personalized Wellness Guidance | Audit existing breathing/stretching presets, define tagging schema, surface recommendations via `PresetRecommendationService` | Mobile + Content | Week 2 |
| 3 | Advanced Insights | Draft dashboard wireframes, outline backend aggregates (Cloud Functions), identify retention controls | Product + Backend | Week 3 |
| 4 | Multi-Device Automation | Spike Apple Watch/Wear OS capability matrix, choose Shortcuts intents to implement first | iOS + Android | Week 4 |
| 5 | Community Features | Author policy doc (moderation, reporting), design prototype of preset sharing modal | PM + Legal + Design | Week 5 |
| 6 | Premium Value Boosters | Map RevenueCat offerings to planned premium features, size content/AI investment | Monetization + Content | Week 6 |

## 2. Competitive Feature Expansion Tracks
1. **Meditation & Breathing Library**
   - Content acquisition/licensing strategy.
   - Metadata schema (tags, duration, mood) and offline caching design.
   - Guided script structure (intro, breathing cadence, stretch cues) with localization notes.
   - Recommendation rules tied to user goals, time of day, and backup streaks.
2. **Sleep & Mood Journal**
   - Entry templates, reminders, analytics integration.
   - Export features and cloud sync requirements.
3. **AI-Assisted Routine Recommendations**
   - Data sources (sleep metrics, focus sessions, journal mood, calendar events).
   - Model approach (rule-based first, progress to ML) and feedback loop for users.
4. **Cross-Domain Analytics Dashboard**
   - Visual correlations (sleep vs focus vs mood) with filter controls.
   - Sharing options (PDF, CSV, secure link).
5. **Widgets & Live Activities**
   - iOS: Lock Screen widgets, Live Activities; Android: Home/Lock Screen widgets, notification updates.
   - Define refresh cadence and battery considerations.
6. **Community Challenges**
   - Challenge templates (solo, invite-only, public).
   - Privacy toggles, moderation workflow, optional leaderboard.

## 3. Prioritization Framework
- **Impact**: user value, differentiation, subscription uplift.
- **Effort**: required disciplines (content, ML, backend), infra changes.
- **Dependencies**: rely on wearable data, AI models, or external partners?
- Use this to produce a quarterly roadmap inside `docs/post_launch_roadmap.md`.

## 4. Next Steps
1. Conduct planning workshop to score each track (impact vs effort) and pick top 2 for next quarter.
2. Create feature briefs and engineering tickets referencing this roadmap.
3. Review compliance & security implications before implementation.

## 5. Competitive Track Deliverables (Near-Term)
| Track | Q1 Deliverable | Notes |
|-------|----------------|-------|
| Meditation & Breathing Library | Ship 10 guided sessions with localized scripts + downloadable packs | Align with Priority #2 tagging schema |
| Sleep & Mood Journal | MVP journal screen + reminder workflow gated behind feature flag | Reuse analytics chart widgets from focus timeline |
| AI-Assisted Routine Recommendations | Implement rule-based engine + telemetry collector for future ML upgrade | Needs privacy review once inference moves to cloud |
| Cross-Domain Analytics Dashboard | Prototype in-app dashboard + export to PDF (no sharing yet) | Depends on backend aggregates from Priority #3 |
| Widgets & Live Activities | Deliver iOS Lock Screen widget + Android home widget for focus timer status | Validate battery usage in QA pass |
| Community Challenges | Build invite-only beta with manual moderation tools | Integrate with RevenueCat entitlements for premium perks |

Keep this document updated as scope evolves; link relevant tickets/PRs under each bullet.
