# UI Design Review

Notes based on current Flutter screen implementations. Validate on-device to
confirm visual outcomes.

## 2026 Q1 Casual Redesign Update
- Implemented core-tab redesign is documented in:
  - `docs/ui_redesign_casual_2026q1.md`
  - `docs/ui_qa_checklist_casual_2026q1.md`
- Updated screens in this cycle:
  - `lib/features/home/casual_home_dashboard.dart`
  - `lib/features/more/more_page.dart`
  - `lib/features/account/account_page.dart`
  - `lib/main.dart` (home tab switch)
- Legacy home dashboards are now marked deprecated to reduce accidental reuse:
  - `lib/features/home/home_dashboard.dart`
  - `lib/features/home/figma_home_dashboard.dart`
  - `lib/features/home/improved_home_dashboard.dart`

## Cross-Screen Themes
- Visual language split between Figma-inspired tabs and standard Material pages.
  Align typography, card elevation, and icon style to reduce cognitive shifts.
- Background treatments vary (solid, gradient, glass). Decide a default pattern
  and reserve gradients for hero surfaces.
- Primary action hierarchy is inconsistent. Standardize a single primary CTA
  placement per screen (top-right, bottom CTA, or floating action button).
- Localization coverage is mixed (some hard-coded English strings remain).

## Screen Notes
Home (`lib/features/home/home_dashboard.dart`):
- Strong greeting + progress story; consider a clearer "Next action" tile.
- Routine cards use the same secondary action; consider distinct secondaries.

Timer (`lib/features/timer/timer_page.dart`, `lib/features/timer/figma_timer_tab.dart`):
- Busy surface: many controls + nudges. Consider progressive disclosure for
  advanced settings.
- Preset chips use Korean strings; ensure localization and consistent casing.

Workout (`lib/features/workout/workout_navigator_page.dart`,
`lib/features/workout/figma_workout_tab.dart`):
- Visual style differs from Home/Timer; align colors and card radii.
- Emphasize the “current workout step” with a stronger visual anchor.

Sleep (`lib/features/sleep/figma_sleep_tab.dart`,
`lib/features/sleep/sleep_analysis_detail_page.dart`):
- Cosmic theme feels distinct; ensure it still matches app typography scale.
- Sleep analysis detail could use clearer section headers and data grouping.

Stats (`lib/features/stats/stats_page.dart`,
`lib/features/stats/cross_domain_dashboard_page.dart`):
- Two dashboards with different hierarchy; consider merging or aligning layout.
- Chart cards: standardize spacing and caption styles.

Journal (`lib/features/journal/journal_page.dart`):
- Calendar + entries benefit from a stronger empty state and date filter badge.

Community (`lib/features/community/community_challenges_page.dart`):
- Create/join sheets are functional but plain; add visual tiering and summary
  stats on cards.
- Leaderboard cards should surface rank and progress at a glance.

Backup (`lib/features/backup/backup_page.dart`):
- Consider elevating the most recent backup status in a hero card.
- Add quick CTA for “Create backup now” with visible state feedback.

Account (`lib/features/account/account_page.dart`):
- Section density is high; group critical actions into visual blocks.
- Highlight premium status distinctly from general settings.

Paywall (`lib/features/subscription/paywall_page.dart`):
- Package tiles are list-based; consider a grid or segmented layout for plan
  comparison.
- Add a stronger hero section explaining benefits and value proof.

Life Buddy (`lib/features/life_buddy/life_buddy_page.dart`):
- Ensure companion state changes have clear micro-animations and feedback.
- Distinguish quests vs. narrative content with different card styles.

Wearable (`lib/features/wearable/wearable_insights_page.dart`):
- Integrate wearable data with consistent progress visualization patterns.

Schedule (`lib/features/schedule/schedule_page.dart`):
- Clarify primary time slots vs. secondary details with spacing + type weight.

Onboarding (`lib/features/onboarding/onboarding_page.dart`):
- Add a more explicit progress indicator and stronger call-to-action on final
  step.

More (`lib/features/more/more_page.dart`):
- Grid uses 4 columns; consider 3 on smaller phones to improve tap targets.
- Ensure icon color contrast on light backgrounds.
