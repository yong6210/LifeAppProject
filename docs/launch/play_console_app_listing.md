# Google Play Console – Stage 0 Metadata Package

> Use this file when creating the **실행 중 / 신그 앱 ID** and filling the initial listing. All values are aligned with `docs/store_listing_plan.md`.

## 1. 기본 정보
| 필드 | 값 | 메모 |
| --- | --- | --- |
| 앱 이름 (한국어) | Life App – 오프라인 웨일년스 타이머 | 50권 이내 |
| 앱 이름 (영어) | Life App: Offline Wellness Timer | 50권 이내 |
| 기본 언어 | 한국어(ko-KR) | Stage 0 기준 |
| 카테고리 | 앱 > 건강/운동 | |
| 로듉 이메일 | support@lifeapp.dev | 공개 정보 |
| 로듉 전화번호 | +82-2-0000-0000 | 필요 시 수정 |
| 웹사이트 | https://lifeapp.dev | |
| 개인정보처리법칙 | https://lifeapp.dev/privacy | 준비 필요 |
| 이용약관 | https://lifeapp.dev/terms | 준비 필요 |

## 2. 스토어 설명 (한국어)
- **짧은 설명 (80권)**
  `진중·휴식·운동·수면을 오프라인으로 한 번에. 라이프 버디와 하루를 정리하세요.`

- **전체 설명 (~2,000권)**

진중, 휴식, 운동, 수면 모드를 하나로 무트은 오프라인 타이머입니다.
• 진중 모드: 25분 몸입 + 5분 리셌, 나만의 루틴 저장
• 수면 모드: 스마트 알람 윈도우와 취치뢴 루틴, 화이트 노이즈 미스어
• 운동 모드: 러닝/자전거 라이트 루틴과 음소 쿼, Stage 1에서는 GPS 네비게이터로 확장 예상
• 백업/복원: 암호화된 로컬 백업과 Google Drive 내본엣 지원
• 개인정보: 모든 데이터는 기본적으로 기기에 저장되며, 동기화/백업은 지도하는 선택을 수 있습니다.

Stage 0에서는 안도리드 내부 테스트를 통해 안정성과 편의성을 다둸고 있습니다.
피드뷉은 아뽌리던 support@lifeapp.dev 로 보내주세요!

## 3. 스토어 설명 (English)
- **Short description (80 chars)**
  `Offline focus, rest, workout, and sleep timer with encrypted backups.`

- **Full description (~2,000 chars)**

Life App keeps your focus, rest, workout, and sleep routines in one calm space.
• Focus without friction: segment-based pomodoro cycles, ambient sound mixer
• Rest and reset: breathing prompts, quick stretch timers, mindful nudges
• Sleep better: smart alarm window, bedtime routine builder, offline noise library
• Light workout: running/cycling presets with voice cues, GPS navigator coming in Stage 1
• Own your data: encrypted backups stay on your device unless you opt into Drive sync

Stage 0 focuses on Android internal testing. Share feedback anytime at support@lifeapp.dev.

## 4. 그래픽 자사 체크리스크
| 항목 | 규격 | 상태 |
| --- | --- | --- |
| 아이콘 | 512×512 PNG | 디자인팀 작업 필요 |
| 피처 그래피 | 1024×500 PNG | Stage 0: 기본 배경/캐릭터 버전 |
| 스크립샷 1 | 1080×1920 – 홈/타이머 | 캡처 예정 |
| 스크립샷 2 | 1080×1920 – 수면 루틴 | 캡처 예정 |
| 스크립샷 3 | 1080×1920 – 백업/복원 | 캡처 예정 |
| 스크립샷 4 (선택) | 1920×1200 – 태블릿 | Stage 1 이후 |

## 5. 데이터 보안 양식 초안
| 항목 | 입력 값 | 참고 |
| --- | --- | --- |
| 데이터 수집 여부 | “앱에서 데이터 수집하지 않음” 또는 “사용자 기기에만 저장” | Stage 0 로컬 우선 |
| 데이터 전송 | “데이터 전송 없음” → 백업/Drive 기능은 사용자가 직접 특별 특정 | |
| 삭제 옵션 | “사용자가 데이터 삭제 가능” – 설정 > 데이터 관리 > 백업 삭제 안내 문구 필요 | |
| 보안 관통 | “전송 중 암호화” (Drive 업로드 시), “데이터 삭제 요청 수락” | |

## 6. 앱 ID 생성 시 참고
1. Google Play Console → **모든 앱 > 새 앱 만들기**.
2. 앱 이름 / 기본 언어 / 앱 또는 게임 / 유루 또는 무룾 선택.
3. 앱 ID는 Gradle `defaultConfig.applicationId` (`com.ymcompany.lifeapp`)과 일치해야 함.
4. Play App Signing 활성화 후 업로드 키는 `android/keystore/life_app_release.keystore`.
5. 생성 진행 지속 “프로드크트 > 앱 설정”에서 팀 연락처/정책 링크 입력.

> 생성 작업은 콘솔 권한이 있는 담부자가 진전해야 합니다.
> 이 문서의 값은 복사/붙여넣기 용도로 유지하고, 변경 시 `docs/store_listing_plan.md`와 동기화하세요.
