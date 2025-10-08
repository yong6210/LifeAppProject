# Timer Engine Overview

## Modes & Plans
- **Focus**: 4-cycle Pomodoro (집중 + 짧은/긴 휴식 자동 전환).
- **Rest**: 스트레칭/호흡/정리 3단계 마이크로 브레이크.
- **Workout**: 설정한 분량에 맞춰 HIIT 라운드(45초 운동 + 15초 휴식) 자동 생성.
- **Sleep**: 취침 준비 → 이완 → 숙면 단계로 구성, 백그라운드 사운드 지원.

각 세그먼트는 `TimerSegment`로 관리되며, 세그먼트 마다 기록/사운드/자동 전환 플래그를 둡니다 (`lib/features/timer/timer_plan.dart`).

## 상태 & 복구
- `TimerState`는 세그먼트 진행도, 전체 진행도, 사운드 설정을 포함합니다.
- 진행 중 상태는 `SharedPreferences`에 저장되며 앱을 재시작해도 복원됩니다.
- 각 세그먼트 종료 시 자동으로 다음 세그먼트로 전환하거나 일시정지합니다.

## 알림 & 배경
- 세그먼트 종료 시각을 `flutter_local_notifications`로 예약해 앱 종료 후에도 알림이 울립니다 (`lib/services/notification_service.dart`).
- Android에서는 `flutter_foreground_task`를 이용해 포그라운드 서비스가 실행되어 장시간 타이머가 안정적으로 동작합니다 (`lib/services/background/foreground_timer_service.dart`).
- iOS는 백그라운드 오디오 + 로컬 알림을 사용하며, 오디오·processing 백그라운드 모드를 Info.plist에 선언했습니다.
- 복귀 시 남은 시간을 다시 계산하여 진행을 이어갑니다.

## 오디오
- `TimerAudioService`가 `just_audio` + `audio_session`을 이용해 모드별 톤 사운드를 루프로 재생합니다 (`lib/services/audio/timer_audio_service.dart`).
- UI에서 사운드 토글 제공.

## 햅틱
- 세그먼트 시작/완료 시 햅틱 피드백을 발생시켜 모드를 체감할 수 있게 했습니다.
