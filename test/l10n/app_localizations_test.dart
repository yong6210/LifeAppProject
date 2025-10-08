import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations', () {
    test('loads English fallback', () async {
      final l10n = await AppLocalizations.load(const Locale('en'));
      expect(l10n.tr('app_title'), 'Life App');
      expect(l10n.tr('paywall_title'), 'Premium');
      expect(
        l10n.tr('session_duration_minutes', {'minutes': '10'}),
        equals('10 min'),
      );
    });

    test('loads Korean overlay and formats placeholders', () async {
      final l10n = await AppLocalizations.load(const Locale('ko'));
      expect(l10n.tr('account_title'), '계정 & 구독');
      expect(
        l10n.tr('session_duration_minutes', {'minutes': '5'}),
        equals('5분'),
      );
    });

    test('returns key when translation missing in all locales', () async {
      final l10n = await AppLocalizations.load(const Locale('ko'));
      expect(l10n.tr('non_existent_key'), 'non_existent_key');
    });
  });
}
