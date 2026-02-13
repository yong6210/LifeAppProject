import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/features/home/casual_home_dashboard.dart';
import 'package:life_app/features/home/home_dashboard.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/stats_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLegacyHomeWrapper(WidgetTester tester) async {
    final view = tester.view;
    final originalPhysicalSize = view.physicalSize;
    final originalDevicePixelRatio = view.devicePixelRatio;
    view.physicalSize = const Size(1080, 1920);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.physicalSize = originalPhysicalSize;
      view.devicePixelRatio = originalDevicePixelRatio;
    });

    final l10n = AppLocalizations.testing(
      translations: const {
        'casual_home_quick_guided': 'Guided Sessions',
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsFutureProvider
              .overrideWith((ref) async => Settings()..focusMinutes = 25),
          todaySummaryProvider.overrideWith(
            (ref) => Stream.value(
              const TodaySummary(focus: 10, workout: 5, sleep: 120),
            ),
          ),
          streakCountProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            _TestLocalizationsDelegate(l10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const HomeDashboardTab(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('legacy HomeDashboardTab delegates to CasualHomeDashboard',
      (tester) async {
    await pumpLegacyHomeWrapper(tester);
    expect(find.byType(CasualHomeDashboard), findsOneWidget);
  });

  testWidgets('legacy HomeDashboardTab still exposes guided quick entry',
      (tester) async {
    await pumpLegacyHomeWrapper(tester);
    await tester.scrollUntilVisible(
      find.text('Guided Sessions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Guided Sessions'), findsWidgets);
  });
}

class _TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate(this._l10n);

  final AppLocalizations _l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(_l10n);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
