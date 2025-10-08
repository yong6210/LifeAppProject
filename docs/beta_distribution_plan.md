# Beta Distribution Plan (v1.0)

## 1. Goals
- Gather usability and stability feedback from closed cohorts before public launch.
- Validate subscription flows (RevenueCat sandbox → App Store / Play Store test users).
- Exercise backup/restore across device families.

## 2. Milestones
| Phase | Cohort | Size | Focus |
| ----- | ------ | ---- | ----- |
| Alpha (Week 1) | Internal team | 10 | Crash-free rate, critical path bugs. |
| Beta 1 (Week 2) | Power users (Focus communities) | 30 | Timer reliability, sleep alarm accuracy. |
| Beta 2 (Week 3) | Broader wellness testers | 80 | Onboarding, paywall copy, backup success. |

## 3. iOS TestFlight Setup
1. Create `Life App – Beta` build channel in App Store Connect.
2. Upload build via CI (`flutter build ipa` + Fastlane deliver).
3. Fill TestFlight metadata (What to test, contact info, privacy policy).
4. Invite internal testers (Apple IDs) → auto-accept deployments.
5. For external testers:
   - Submit beta app review (include offline timer test notes).
   - Create email list; include instructions for RevenueCat sandbox (use provided StoreKit Configuration or sandbox user).
6. Capture feedback via TestFlight or redirect to Notion form.

## 4. Google Play Internal Testing
1. Create `internal` (up to 100 testers) and `closed` tracks in Play Console.
2. Upload `.aab` via CI (`flutter build appbundle`).
3. Provide release notes (focus on offline reliability + backup).
4. Manage testers via Google Groups; invite using corporate Gmail or pre-launch community list.
5. Ensure Play Billing license tester accounts are enrolled for subscription purchases.

## 5. Feedback Channels
- **Primary**: Notion feedback board (template includes device, build, repro steps, log attachments).
- **Secondary**: In-app “Send feedback” deep link to email `beta@lifeapp.sh` with device info stub.
- Weekly sync: Product + Engineering triage session to review backlog from beta testers.

## 6. Instrumentation & Telemetry
- Enable Firebase Analytics `beta_cohort` user property via remote config flag.
- Segment Crashlytics dashboards by build channel (alpha/beta/prod).
- Use custom events `beta_feedback_submitted`, `beta_issue_reported` for tracking.

## 7. Release Criteria (Exit Beta)
- Crash-free sessions ≥ 99.5% across core devices.
- Timer accuracy skew ≥ 95% within ±60s (validated via diagnostics export).
- At least 10 successful backup/restore reports per platform.
- Net promoter score (form) ≥ 40.

## 8. Operations
- Build promotion cadence: every Monday + hotfixes as needed.
- Maintain changelog in `docs/releases/` for testers.
- Archive feedback outcomes in Notion; feed into backlog grooming.

## 9. Owners
- **Release manager**: Builds & submission.
- **QA lead**: Testing matrix execution, bug triage.
- **Support lead**: Beta inbox, user communication.

Update this document after each beta wave with metrics and key learnings.
