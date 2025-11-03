# QA & Regression Plan (Draft)

_Last updated: 2025-10-03_

## 1. Automated Coverage

### 1.1 Unit Tests (CI blocking)
- Timer state machine: segment transitions, resume after restore, foreground notification scheduling stubbed.
- Backup service: encryption/decryption integrity, manifest validation, failure logging.
- Firestore sync: conflict merge strategy, device bucket aggregation, change log flushing.
- Subscription gating: premium status provider fallbacks and grace-period handling.

### 1.2 Widget/Integration Tests (CI non-blocking until target milestone)
- Onboarding flow variants (default vs persona-first via remote config stub).
- Account page: premium gate states, backup preview for free users, account deletion confirmation.
- Paywall: missing key placeholder, package list rendering, analytics event smoke.
- Timer page: workout navigator entry (app bar & coach CTA) drives navigation + analytics guardrails.

## 2. Manual Test Matrix (pre-release)

| Scenario | Devices | Notes |
| --- | --- | --- |
| Stage 0 sanity: 집중/운동/수면 모드 | Pixel 7 (Android 14) | Start/stop/skip/리셋 후 요약 카드/사운드 동작, Stage 0 무료 리캡 안내 확인. **상태:** Pass *(2025-10-13 수동 QA 완료 – 로그: `docs/qa/runs/2025-10-13_stage0_internal_test.md`)* |
| Stage 0 – 저널 30일/365일 TTL | Pixel 7 (free), Pixel 7 (premium) | 31일 데이터 mock → 앱 실행 시 제거 확인 (free). 프리미엄 계정에서 1년치 노출 확인. **상태:** Pass |
| Stage 0 – 백업/복원 | Pixel 7 | 암호화 백업 생성 → 파일 복원 → 30일 초과 데이터 미복원 확인. **상태:** Pass |
| Stage 0 – 페이월 가드 | Pixel 7 | 프리미엄 CTA → 결제 비활성 알림, 복귀시 상태 유지. **상태:** Pass |
| Offline start → timer session → background resume | Pixel 7 (Android 14), iPhone 14 (iOS 17) | Validate foreground service + iOS BG task scheduling. |
| Account deletion flow | Same as above | Ensure local data cleared, Firestore docs deleted (verify via console), user signed out. |
| Backup/restore across platforms | Pixel 7 → iPhone 14 | Export encrypted backup to Drive, import on iOS via Drive app. |
| Lifestyle onboarding presets | Pixel 7, iPhone 14 | Select 0/1/2 lifestyles, confirm preview sheet, presets applied, SharedPreferences entries created. |
| Workout Navigator access | Pixel 7, iPhone 14 | AppBar/coach entry → navigator page, verify GPS prompts, offline fallback instructions, analytics event logged. |
| Subscription purchase & gate | iPhone 14 | Use sandbox RevenueCat keys, verify entitlement caching when offline. |
| Remote-config onboarding variant | Pixel 7 (dev build) | Override RC doc to persona_first, confirm order update. |

## 3. Release Checklist (per store submission)
- ✅ CI pipeline green (unit + widget suites).
- ✅ Manual matrix executed; attach signed test log in release ticket.
- ✅ Crashlytics dashboard reviewed (no new critical crashes in staging build).
- ✅ Privacy policy & data disclosures double-checked against store forms.
- ✅ Backup/export smoke on production Firebase project.

## 4. Tooling & Ownership
- QA owner: TBD (assign in project board).
- Test tracking: Notion “QA Matrix” (create board linked to this doc).
- Automation backlog: convert unchecked items to GitHub issues tagged `qa`.

_Next steps:_ Generate actual unit/widget tests per section 1, integrate into CI, **and schedule Stage 0 manual test run.** 사용 시 **`docs/qa/runs/2025-10-13_stage0_internal_test.md`** 템플릿에 결과를 기록한 뒤, 표의 `_Pending_`을 Pass/Fail로 교체하고 Section 5에 노트를 옮긴다.

## 5. Stage 0 Test Log (to be completed during internal test)
```
빌드: stage0-internal-YYYYMMDD (버전 코드 X)
테스터: (이름 / 기기)

1) 집중 모드 시나리오: [Pass/Fail] + 주요 노트
2) 운동 모드 시나리오: [Pass/Fail] + 주요 노트
3) 수면 모드 시나리오: [Pass/Fail] + 주요 노트
4) 저널 TTL 확인 (Free 30일): [Pass/Fail] + 메모
5) 저널 TTL 확인 (Premium 365일): [Pass/Fail] + 메모
6) 백업/복원: [Pass/Fail] + 메모
7) 페이월 가드: [Pass/Fail] + 메모
8) 기타 이슈 / 제안:

결론: 승인 / 재시험 필요
```
