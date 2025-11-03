# Android Internal Test Track Checklist (Stage 0)

## 1. 목적
- Google Play Console 내부 테스트 트랙을 이용해 Pixel 6, Galaxy A 시리즈에서 APK/AAB 설치 및 핵심 기능을 검증한다.
- 스토어 메타데이터, 개인정보 링크, 결제 비활성 여부를 함께 확인해 Stage 0 출시 준비를 마무리한다.

## 2. 사전 준비
- [ ] Play Console 권한: Release Manager 이상의 권한을 가진 계정 확인.
- [ ] 번들 서명: Play App Signing 사용 여부 결정 및 업로드 키 보관.
- [ ] 패키지명/버전: `com.ymcompany.lifeapp` Stage 0 빌드 버전 코드/이름 확정.
- [ ] 릴리스 노트 초안: 집중·수면 루틴 안정화, 백업 기능 강조.

## 3. 빌드 업로드 절차
1. `flutter build appbundle --flavor staging`
2. Play Console → **출시 > 테스트 > 내부 테스트**
3. 새 릴리스 작성 → AAB 업로드 → 릴리스 이름 `stage0-internal-yyyyMMdd`
4. 앱 무결성 검사 후 경고 확인
5. 테스트 노트에 검증 목표/변경 사항 기재

## 4. 테스터 초대 및 배포
- [ ] Pixel 6, Galaxy A 시리즈 보유자 이메일(2~3명) 수집
- [ ] 테스트 URL 복사 후 Slack/메일로 공유
- [ ] 테스터 승인 상태 확인(대기 → 승인)

## 5. 검증 시나리오
| 분류 | 시나리오 | 기기 |
| ---- | -------- | ---- |
| 설치/실행 | Google Play 통해 설치, 첫 실행 Onboarding 완료 | Pixel 6, Galaxy A |
| 집중 루틴 | 25분 집중/5분 휴식 프리셋 실행, 타이머 백그라운드 유지 | Pixel 6 |
| 수면 루틴 | 수면 루틴 생성 → 알람 예약 → 기상 알림 | Galaxy A |
| 백업/복원 | Google Drive 백업 생성 및 복원 화면 진입 | Pixel 6 |
| 저널/캘린더 | 저널 작성 및 캘린더 표시 확인 | Galaxy A |
| 결제 비활성 | 프리미엄 페이월 진입 시 실제 결제 호출 차단 확인 | 모든 기기 |
| 로그 수집 | `adb logcat`으로 5분 이상 오류 여부 확인 | Pixel 6 |

## 6. 테스트 레포트 양식

테스터: (이름/기기)
빌드: stage0-internal-yyyyMMdd (버전 코드)

1. 설치/실행:
2. 집중 루틴:
3. 수면 루틴:
4. 백업/복원:
5. 저널/캘린더:
6. 기타 발견 이슈:
   결론: 승인 / 재시험 필요

## 7. 완료 조건
- [ ] 모든 테스터가 “승인” 판정을 제출
- [ ] 치명적 크래시/버그 없음, 경미한 이슈는 Stage 0 패치나 Stage 1 백로그로 이관
- [ ] 테스트 결과를 `docs/status/2025-10-11_status_memo.md`에 요약
- [ ] Play Console 내부 테스트 릴리스를 Stage 0 프로덕션 릴리스 기준 버전으로 전환
