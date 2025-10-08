# FLAVOR 기반 Firebase 옵션 로딩

## 현재 상태
- Firebase 초기화는 `lib/core/firebase/firebase_initializer.dart`에서 `firebaseOptionsForCurrentFlavor()`를 호출하며, `lib/core/firebase/firebase_options_factory.dart`에서 `String.fromEnvironment('FLAVOR')` 값에 따라 dev/staging/prod 옵션을 선택합니다.
- 생성된 옵션 파일(`lib/firebase_options_<flavor>.dart`)은 각각 dev/staging/prod Firebase 프로젝트의 API 키, appId, projectId로 업데이트되어 있습니다.
- Android `productFlavors`는 dev/staging/prod 각각 `com.ymcompany.lifeapp.<flavor>`(prod는 기본값)을 사용해 Firebase 앱과 일치하도록 정리되었습니다.
- iOS/macOS 런너 구성도 dev/staging 번들 ID를 `com.ymcompany.lifeapp.dev|staging`으로 맞추고 prod는 기본 ID를 유지합니다. Crashlytics `firebase_app_id_file.json`을 dev/staging/prod 및 기본 경로에 생성했습니다.

## 사용 방법
- 기본값은 staging입니다. 다른 프로젝트를 쓰려면 빌드/실행 시 `--dart-define=FLAVOR=<dev|prod>`를 전달하세요.
  ```bash
  flutter run --flavor dev --target lib/main.dart --dart-define=FLAVOR=dev
  flutter run --flavor prod --target lib/main.dart --dart-define=FLAVOR=prod
  flutter build ios --no-codesign --flavor dev --dart-define=FLAVOR=dev
  ```
- FlutterFire CLI로 설정을 갱신할 때는 `firebase.json`의 출력 경로를 그대로 두고, 각 flavor에 대해 `--out` 경로를 지정해 생성된 JSON/Plist가 올바른 디렉터리에 덮어쓰이도록 합니다.
  ```bash
  flutterfire configure --project life-app-dev --out lib/firebase_options_dev.dart --platforms ios,android
  flutterfire configure --project life-app-prod-8b6e4 --out lib/firebase_options_prod.dart --platforms ios,android
  ```

## TODO / 남은 작업
- Android 에뮬레이터 기준으로 `flutter run --flavor dev|staging|prod --dart-define=FLAVOR=…`를 실행해 앱이 정상 구동되는 것을 확인했습니다. Kotlin incremental cache 경고가 다수 발생하지만 캐시 제거 후 재빌드하면 사라지므로 기능 영향은 없습니다.
- macOS 데스크톱에서도 `flutter run -d macos --flavor dev|staging|prod --dart-define=FLAVOR=<flavor> --target lib/main.dart` 조합이 빌드/실행되었습니다. 세 경우 모두 `Failed to foreground app; open returned 1` 로그가 남지만 앱 구동에는 영향이 없었습니다.
- iOS는 `flutter build ios --no-codesign --flavor …`가 개발자 Team 미지정으로 차단됩니다. 시뮬레이터 빌드는 `--simulator` 옵션으로 확인 가능하며, 실기기 배포는 Xcode에서 Team을 지정한 후 재실행해야 합니다.
- `flutter test` 전체가 성공했습니다.
- Analyzer는 현재 Flutter SDK의 deprecated API에 대한 info 수준 경고를 출력합니다(`lib/design/app_theme.dart`, `lib/features/backup/backup_page.dart`, `lib/features/timer/timer_page.dart` 등). SDK 업그레이드 시 대응하거나 `ignore` 정책을 결정할 필요가 있습니다.
- flavor마다 Smoke Test를 CI에 추가하면 staging 외 환경에서도 Firebase 연동을 미리 검증할 수 있습니다.
