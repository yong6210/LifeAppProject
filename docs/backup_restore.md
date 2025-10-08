# Backup & Restore Guide

## 백업
1. 앱 우측 상단 클라우드 아이콘을 눌러 `백업 & 복원` 화면으로 이동합니다.
2. `원탭 백업` 버튼을 누르면 로컬 Isar DB가 암호화되어 `.lifeappbackup` 파일이 생성됩니다.
3. 공유 시트를 통해 Google Drive, iCloud Drive 등 원하는 저장소에 업로드하세요.
4. 백업이 성공하면 설정의 `lastBackupAt` 값이 현재 시각으로 갱신됩니다.

## 복원
1. 동일 화면에서 `백업 복원` 버튼을 누릅니다.
2. 파일 선택기에서 `.lifeappbackup` 파일을 선택합니다.
3. 암호화된 백업이 복호화되어 로컬 DB가 교체되며, 앱이 자동으로 DB를 재오픈합니다.
4. 복원이 끝나면 데이터가 즉시 반영됩니다.

## 기술 메모
- 데이터는 AES-256-GCM으로 암호화되며 키는 `FlutterSecureStorage`(Keychain/Keystore)에 저장됩니다.
- 백업 파일은 JSON 포맷이며 `nonce`, `ciphertext`, `mac`, `schemaVersion`, `createdAt` 메타데이터를 포함합니다.
- 복원 시 기존 Isar 인스턴스를 닫고, 백업 파일 내용으로 DB 파일을 덮어쓴 뒤 다시 오픈합니다.
- 공유 시트를 사용하므로 Google Drive / iCloud 등 시스템 공유 대상에 자연스럽게 업로드 가능합니다.
