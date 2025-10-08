# Competitive Landscape & UI / Feature Recommendations

This note compiles a brief survey of popular lifestyle apps around sleep and focus (based on Calm, Headspace, Sleep Cycle, Rise, Pillow, Focus To-Do, etc.) and turns those observations into concrete suggestions for Life App.

## 1. Competitor Highlights
- **Sleep Cycle / Pillow**: microphone or accelerometer based sleep tracking, smart alarm windows, nightly timeline, daily score + trend charts.
- **Calm / Headspace**: curated meditation & breathing libraries, day-part playlists (morning focus, afternoon break, evening wind-down), streaks and badges.
- **Rise / SleepTown**: energy forecasting, chronotype insights, actionable tips aligned with upcoming calendar events.
- **Focus Keeper / Forest / Focus To-Do**: Pomodoro timers with streak tracking, quick-start presets, lock-screen widgets, community challenges (shared goals).

## 2. Recommended UI Enhancements
1. **Home dashboard refresh**
   - Split into "현재 집중" / "수면 분석" / "오늘 할 일" 섹션.
   - Highlight streaks, next scheduled routine, and quick shortcuts (Focus / Sleep / Journal).
2. **Sleep timeline card**
   - Show bedtime → wake time, restful vs noisy segments (using `SleepSoundSummary`), and smart alarm window.
   - Use contextual colors: blue = restful, amber = noisy.
3. **Focus session overview**
   - Display previous day focus minutes vs goal, top routines used, and suggestions (예: "다음 휴식까지 10분 남았어요").
4. **Journal quick add**
   - Floating action button for rapid entry (mood + 수면 시간), plus recent notes carousel for reflection.
5. **Personalized banners**
   - Rotate between breathing/movement prompts, bedtime reminders, and backup nudges based on analytics (실험 시 A/B 테스트 가능).

## 3. Feature Recommendations
1. **Sleep Sound MVP (모바일 단독)**
   - Utilize `SleepSoundRecorder` + `SleepSoundAnalyzer` to detect noisy events, restful ratio, and provide nightly feedback 보트.
   - Next iteration: overlay results with wearable data when available.
2. **Guided wind-down flows**
   - Offer 10~20분짜리 breathing/stretch playlists linked with sleep mode (Calm/Headspace 유사).
3. **Calendar-aware routines**
   - If 예정된 미팅/수업이 있으면 "집중 모드" 또는 "회복 모드" 추천 (Rise 접근 참고).
4. **Community / Challenge (Opt-in)**
   - 예: "이번 주 집중 10시간 챌린지"를 친구와 공유, 개인정보 보호 기반.
5. **Widgets & Live Activities**
   - iOS Lock Screen / Live Activity, Android 홈 위젯으로 타이머 제어, 수면 타임라인, 다음 알람 카운트다운 표시.

## 4. Prioritized Next Actions
1. **Finish Release Prep** → doc: `docs/release/release_prep_plan.md`.
2. **Sleep Sound PoC UX**
   - Build UI card that surfaces `SleepSoundSummary` (restful ratio, loud events) with feedback text ("전체 수면의 72%가 조용했습니다" 등).
3. **Guided Wind-down MVP**
   - Curate 3~5 오디오/동영상 콘텐츠와 온보딩 연계.
4. **Focus Dashboard Refresh**
   - Align with design sprint (감정 몰입형 UI) and include streaks/goal progress.
5. **Wearable Sync opt-in flow**
   - Implement permission screens, nightly summary merging, privacy notes.

## 5. Design Notes
- 강조 색상: 집중 = 주황, 수면 = 파랑, 회복 = 보라.
- 배지/리워드 시스템은 간결하게 (예: 3일 연속 목표 달성 시 "Consistency" 배지).
- 알림문구 예시: "22시 수면 루틴 시작은 어떨까요? 어젯밤보다 15분 빠른 기상 목표입니다.".

Use this document alongside `docs/security_competitive_roadmap.md` to plan UI mockups, product requirements, and sprint tickets.
