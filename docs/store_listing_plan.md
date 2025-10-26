# Store Listing Plan (App Store & Google Play)

## 1. Summary
- **App Name**: Life App – Offline Wellness Timer
- **Subtitle (iOS)**: Focus, rest, workout, and sleep in one calm routine.
- **Short Description (Play Store)**: Offline-first focus, rest, workout, and sleep timer with one-tap backup and cross-device sync.

## 2. Primary Messaging Pillars
1. **Offline-first** – timers, routines, and sounds work without network.
2. **Privacy by design** – on-device personalization with explicit opt-ins for sync; clear “own your data” narrative.
3. **Rapid recovery** – light sync and encrypted backups get users started in seconds.
4. **All-in-one wellness** – focus, rest, workout, and sleep flow together.

## 3. Metadata Checklist
| Store | Field | Status | Notes |
| ----- | ----- | ------ | ----- |
| iOS | App Name | Draft | 30 char cap (current draft 28). |
| iOS | Subtitle | Draft | 30 char cap. |
| iOS | Keywords | Pending | Target: focus timer, sleep sounds, pomodoro, backup timer. |
| iOS | Promotional Text | Draft | “Stay on track anywhere with offline timers, smart sleep alarms, and one-tap backups.” |
| iOS | Description | Draft | Use 3-section narrative (Focus, Backup, Premium). |
| iOS | Screenshots | Pending | Need 6.7", 6.5", 5.5", iPad, plus dark mode variants. |
| iOS | App Privacy | Pending | Reuse privacy matrix from `docs/privacy_policy_draft.md`. |
| Android | Title | Draft | “Life App: Offline Wellness Timer” (50 char cap). |
| Android | Short Description | Draft | 80 char cap. |
| Android | Full Description | Draft | ~2,000 chars; mirror iOS copy. |
| Android | Feature Graphic | Pending | 1024×500; use routine card motif. |
| Android | Screenshots | Pending | Phone 6.7", 6.0", tablet 10". |
| Android | Data Safety | Pending | Align with privacy disclosures. |

## 4. Description Outline (Shared)
```
Headline: “Offline-first focus, rest, workout, and sleep timer.”

Section 1 – Focus without friction
- Segment-based focus/rest cycles
- Adaptive soundscapes and blockers
- Smart sleep alarm window

Section 2 – Own your data
- Encrypted backups to Drive/iCloud
- Light sync for instant setup on new devices
- Diagnostics export for compliance teams
- Personalization stays on your device unless you turn on cloud sync

Section 3 – Premium perks
- Unlimited presets & advanced stats
- Automatic weekly backups
- Cross-platform subscription recognition via RevenueCat

CTA: “Start your routine today—offline, secure, and distraction-free.”
```

## 5. Asset Production
- **Screenshots**: Capture Home, Timer, Sleep editor, Backup, Paywall, Stats (light + dark). Use Figma frame templates.
- **Videos**: Optional; consider 15s motion graphic showing offline use + quick backup.
- **Icons**: Ensure 512×512 Play icon and 1024×1024 iOS marketing icon meet platform safe zones.
- **Capture workflow**: Follow `docs/design/mobile_screenshot_capture.md` for mobile order, theming, and export steps.

## 6. Localization Roadmap
- Phase 1: English, Korean (already in-app).
- Phase 2: Japanese, German once ARB files ready; update listings accordingly.

## 7. Locale-Specific Messaging Guardrails
- **United States** – Highlight consent-first personalization (“Keep routines on-device until you choose to sync”), mention CPRA-aligned data controls, and use direct Plain English copy. Include privacy badge in first or second screenshot.
- **Korea** – Emphasize 정성 어린 케어 and 데이터 자가 보관(암호화 백업) 메시지. 안내 문구엔 존댓말 사용, 데이터 삭제/동기화 해지 절차를 간단히 설명.
- Adjust pricing blurb per locale (KR 통화 단위, US 달러) and ensure screenshots show locale-appropriate tone selection (친구형/코치형 라이프 버디).
- Data Safety/App Privacy sections must mirror `docs/privacy_policy_draft.md` regional disclosures; double-check toggle names before submission.

## 8. Timeline
- Week 1: Finalize copy, review with marketing.
- Week 2: Produce screenshots/video, gather approvals.
- Week 3: Submit iOS metadata for App Review pre-approval; upload Android listing to internal testing.

## 9. Owners
- **Copy**: PM/Content lead.
- **Assets**: Design.
- **Submission**: Release manager.

Track progress in the launch checklist; update this file with final copy revisions before submission.
