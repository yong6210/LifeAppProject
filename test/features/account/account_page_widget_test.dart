import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/accessibility_providers.dart';
import 'package:life_app/providers/account_providers.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/diagnostics_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/accessibility/accessibility_controller.dart';
import 'package:life_app/services/account/account_deletion_service.dart';
import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const nonPremiumStatus = PremiumStatus(
    isPremium: false,
    usesCachedValue: false,
    hasCachedValue: true,
    isLoading: false,
    revenueCatAvailable: false,
    isInGracePeriod: false,
    gracePeriodEndsAt: null,
    expirationDate: null,
    isExpired: false,
  );

  const premiumStatus = PremiumStatus(
    isPremium: true,
    usesCachedValue: false,
    hasCachedValue: true,
    isLoading: false,
    revenueCatAvailable: true,
    isInGracePeriod: false,
    gracePeriodEndsAt: null,
    expirationDate: null,
    isExpired: false,
  );

  final sample = TimerAccuracySample(
    recordedAt: DateTime.utc(2025, 1, 1),
    mode: 'focus',
    segmentId: 'segment-1',
    segmentLabel: 'Focus',
    skewMs: 12,
  );

  Future<void> pumpAccountPage(
    WidgetTester tester, {
    required PremiumStatus status,
    required List<TimerAccuracySample> samples,
    required Settings settings,
    AccessibilityController? accessibilityController,
  }) async {
    final accessibilityStub =
        accessibilityController ?? _FakeAccessibilityController();
    final l10n = AppLocalizations.testing(translations: _testTranslations);
    final view = tester.view;
    final originalPhysicalSize = view.physicalSize;
    final originalDevicePixelRatio = view.devicePixelRatio;
    view.physicalSize = const Size(1080, 1920);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.physicalSize = originalPhysicalSize;
      view.devicePixelRatio = originalDevicePixelRatio;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          authControllerProvider.overrideWith(() => _FakeAuthController(null)),
          accountDeletionControllerProvider.overrideWith(
            _FakeAccountDeletionController.new,
          ),
          accessibilityControllerProvider.overrideWith(() => accessibilityStub),
          premiumStatusProvider.overrideWithValue(status),
          settingsFutureProvider.overrideWith((ref) async => settings),
          timerAccuracySamplesProvider.overrideWith((ref) async => samples),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            _TestLocalizationsDelegate(l10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const AccountPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('shows backup and diagnostics premium upsells for free users', (
    tester,
  ) async {
    final settings = Settings()
      ..backupPreferredProvider = 'Drive'
      ..backupHistory = [];

    await pumpAccountPage(
      tester,
      status: nonPremiumStatus,
      samples: [sample],
      settings: settings,
    );

    expect(
      find.text('Timer accuracy samples', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Recent measurements compare scheduled',
        findRichText: true,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides premium upsells for paid users and shows insights', (
    tester,
  ) async {
    final settings = Settings()
      ..backupPreferredProvider = 'Drive'
      ..backupHistory = [];

    await pumpAccountPage(
      tester,
      status: premiumStatus,
      samples: [sample],
      settings: settings,
    );

    expect(
      find.text('Timer accuracy samples', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.ios_share_outlined), findsOneWidget);
  });

  testWidgets('accessibility toggle updates controller', (tester) async {
    final settings = Settings()..backupPreferredProvider = 'Drive';
    final accessibilityStub = _FakeAccessibilityController();

    await pumpAccountPage(
      tester,
      status: nonPremiumStatus,
      samples: const [],
      settings: settings,
      accessibilityController: accessibilityStub,
    );

    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Reduce motion & haptics',
    );
    expect(switchFinder, findsOneWidget);
    expect(accessibilityStub.value, isFalse);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(accessibilityStub.value, isTrue);
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);

  final User? _user;

  @override
  Future<User?> build() async => _user;
}

class _FakeAccountDeletionController extends AccountDeletionController {
  @override
  Future<AccountDeletionResult?> build() async => null;
}

class _FakeAccessibilityController extends AccessibilityController {
  bool _value = false;

  bool get value => _value;

  @override
  Future<AccessibilityState> build() async =>
      AccessibilityState(reducedMotion: _value);

  @override
  Future<void> setReducedMotion(bool value) async {
    _value = value;
    state = AsyncData(AccessibilityState(reducedMotion: value));
  }
}

class _TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate(this.l10n);

  final AppLocalizations l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(l10n);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

const Map<String, String> _testTranslations = <String, String>{
  'backup_history_title': 'Backup & Restore History',
  'backup_preferred_label': 'Preferred provider: {provider}',
  'backup_premium_header': 'Premium Feature',
  'backup_premium_message':
      'Automatic backups and full history are available with Premium. Upgrade to view the complete log on every device.',
  'backup_upgrade_button': 'See Premium Options',
  'backup_upgrade_semantics_label': 'Upgrade to unlock full backup history',
  'backup_upgrade_semantics_hint':
      'Opens the premium options screen to subscribe and access complete backup history.',
  'backup_history_recent_only':
      'Only the most recent backup is available on the free plan.',
  'account_diagnostics_title': 'Timer accuracy samples',
  'account_diagnostics_body':
      'Recent measurements compare scheduled segment completions with actual delivery.',
  'account_diagnostics_premium_title': 'Unlock detailed diagnostics',
  'account_diagnostics_premium_body':
      'Premium shows percentile trends, mode-level breakdowns, and calibration tips.',
  'account_diagnostics_premium_button': 'Try Premium insights',
  'account_diagnostics_insights_title': 'Detailed insights',
  'account_diagnostics_insights_description':
      'Median, p95, and per-mode stats update as you record calibration samples.',
  'account_diagnostics_median_label': 'Median skew: {value}',
  'account_diagnostics_p95_label': '95th percentile: {value}',
  'account_diagnostics_late_early': 'Late {late} • Early {early}',
  'account_diagnostics_mode_item':
      '{mode}: avg {avg}, max {max}, samples {count}',
  'account_diagnostics_summary_heading': 'Summary (last {count})',
  'account_diagnostics_summary_avg': 'Average skew: {value}',
  'account_diagnostics_summary_max': 'Max deviation: {value}',
  'account_diagnostics_summary_within_target':
      'Within target window: {percent}%',
  'account_diagnostics_entry':
      '{timestamp} · {mode} ({segment}) - skew {value}',
  'account_diagnostics_skew_late': 'Late by {value}',
  'account_accessibility_title': 'Accessibility',
  'account_accessibility_body':
      'Adjust reduced motion to limit animations and haptic feedback across the app.',
  'account_accessibility_reduced_motion': 'Reduce motion & haptics',
  'account_personalization_title': 'Routine personalization',
  'account_personalization_body':
      'Choose how suggestions work and whether to sync them.',
  'account_personalization_enabled_title': 'Personalized suggestions',
  'account_personalization_enabled_subtitle':
      'Use timer history to tailor your routine.',
  'account_personalization_sync_title': 'Sync personalization across devices',
  'account_personalization_sync_subtitle':
      'Upload anonymized scores to reuse on other devices.',
  'account_personalization_sync_disabled':
      'Enable personalized suggestions to sync.',
  'account_personalization_tone_title': 'Life Buddy tone',
  'account_personalization_tone_friend': 'Friend',
  'account_personalization_tone_friend_description':
      'Warm encouragement and casual check-ins.',
  'account_personalization_tone_coach': 'Coach',
  'account_personalization_tone_coach_description':
      'Direct guidance focused on goals.',
  'generic_settings_error': 'Settings error: {error}',
  'backup_history_empty': 'No backups yet.',
  'backup_history_recent_label': 'Most recent backup',
};
