# Post-launch Roadmap (v1.0)

## Guiding Principles
- Deliver features that reinforce the core value: offline-first wellness routines with owned data.
- Use analytics + user feedback to prioritize; maintain sustainable cadence (monthly increments).
- Keep infrastructure lean—prefer client-side enhancements unless server value is clear.

## Horizon Overview
| Horizon | Timeline | Theme | Key Outcomes |
| ------- | -------- | ----- | ------------ |
| H1 | Month 1–2 | Reliability & Trust | Nail timer accuracy, backup adoption, subscription stability. |
| H2 | Month 3–4 | Personalization & Sharing | Deeper stats, routine sharing, watch integrations. |
| H3 | Month 5–6 | Community & Expansion | Preset marketplace, guided programs, new locales. |

## Horizon 1 – Reliability & Trust (Month 1–2)
1. **Timer resilience**
   - Expand diagnostics export to auto-upload (with opt-in).
   - Implement automated skew alarms via Firebase Functions.
2. **Backup adoption**
   - Add weekly backup reminder banner + completion badge.
   - Provide backup integrity check (hash verification UI).
3. **Subscription polish**
   - RevenueCat webhook processor to update entitlement doc.
   - In-app billing issue assistant (link to Apple/Google refund flows).

## Horizon 2 – Personalization & Sharing (Month 3–4)
1. **Routine presets**
   - Allow export/import of preset bundles (JSON file + share sheet).
   - Provide curated presets (e.g., “Morning Focus”, “Workout Warmup”).
2. **Advanced stats**
   - Weekly/monthly charts with goals and streak insights.
   - Add annotation of key events (new preset, backup) on timeline.
3. **Wearable support**
   - Apple Watch complication (start/stop focus session).
   - Wear OS tile + haptic cues.

## Horizon 3 – Community & Expansion (Month 5–6)
1. **Preset marketplace** (opt-in)
   - Moderated gallery of community routines.
   - Premium benefit: featured routines & advanced filters.
2. **Guided programs**
   - Add light-touch coaching sequences (e.g., 30-day focus challenge).
   - Partner content (calming sounds, micro workouts).
3. **Localization & accessibility**
   - Extend to Japanese & German locales.
   - Accessibility re-audit including switch control & captions (if video content added).

## Cross-cutting Initiatives
- **Performance budget**: keep startup < 2.5s, memory < 250 MB; revisit after major features.
- **Privacy & Compliance**: annual review (see `docs/compliance_audit_plan.md`, pending).
- **Support & Community**: monthly AMA with beta testers; update FAQ.

## Decision Log
- Store roadmap in Notion roadmap board; sync with engineering sprint planning.
- Revisit roadmap quarterly based on KPI review.
