import 'package:flutter/widgets.dart';

import 'package:life_app/l10n/app_localizations.dart';

AppLocalizations? _cachedLocalizations;
Locale? _cachedLocale;

Future<AppLocalizations> loadAppLocalizations([Locale? override]) async {
  WidgetsFlutterBinding.ensureInitialized();
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final locale = override ?? dispatcher.locale;

  if (_cachedLocalizations != null && _cachedLocale == locale) {
    return _cachedLocalizations!;
  }

  try {
    _cachedLocalizations = await AppLocalizations.load(locale);
    _cachedLocale = locale;
    return _cachedLocalizations!;
  } catch (_) {
    if (locale.languageCode != 'en') {
      _cachedLocalizations = await AppLocalizations.load(const Locale('en'));
      _cachedLocale = const Locale('en');
      return _cachedLocalizations!;
    }
    rethrow;
  }
}
