/// RevenueCat SDK public keys for each platform.
///
/// Replace the placeholder strings with your actual RevenueCat public SDK keys
/// or provide them at runtime using `--dart-define`:
/// `--dart-define=REVENUECAT_ANDROID_KEY=your_key`.
class RevenueCatKeys {
  RevenueCatKeys._();

  static const String androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: 'test_TSvBcFkKMdEMgIEDoBnEQnOBKOT',
  );

  static const String iosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: 'test_TSvBcFkKMdEMgIEDoBnEQnOBKOT',
  );
}
