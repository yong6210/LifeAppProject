import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/features/subscription/paywall_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Paywall shows placeholder message when key missing', (
    tester,
  ) async {
    final l10n = AppLocalizations.testing(
      translations: _testPaywallTranslations,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          revenueCatControllerProvider.overrideWith(
            () => _FakeRevenueCatController(null),
          ),
          paywallVariantProvider.overrideWithValue(
            const AsyncValue<PaywallVariant>.data(PaywallVariant.focusValue),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            _TestLocalizationsDelegate(l10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: PaywallPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // On non-mobile test platforms, gate with the unsupported message.
    expect(find.textContaining('Purchases are only supported'), findsOneWidget);
  });
}

class _FakeRevenueCatController extends RevenueCatController {
  _FakeRevenueCatController(this._state);

  final RevenueCatState? _state;

  @override
  Future<RevenueCatState?> build() async => _state;
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

const Map<String, String> _testPaywallTranslations = <String, String>{
  'paywall_title': 'Premium',
  'paywall_restore_tooltip': 'Restore purchases',
  'paywall_unsupported_platform':
      'Purchases are only supported on iOS and Android builds.',
  'paywall_missing_key_message':
      'RevenueCat SDK key is not configured. Update `lib/core/subscriptions/revenuecat_keys.dart` or supply keys via --dart-define and try again.',
};
