import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations._(
    this.locale,
    this._localizedStrings,
    this._fallbackStrings,
  );

  final Locale locale;
  final Map<String, String> _localizedStrings;
  final Map<String, String> _fallbackStrings;

  static const supportedLocales = <Locale>[Locale('en'), Locale('ko')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(result != null, 'AppLocalizations not found in widget tree');
    return result!;
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final fallback = await _loadLocale(const Locale('en'));
    final overlays = await Future.wait(
      _parentLocales(locale).map(_loadLocale),
    );
    final combined = Map<String, String>.from(fallback);
    for (final overlay in overlays) {
      combined.addAll(overlay);
    }
    return AppLocalizations._(locale, combined, fallback);
  }

  static Future<Map<String, String>> _loadLocale(Locale locale) async {
    final code = locale.languageCode;
    final script = locale.scriptCode;
    final country = locale.countryCode;
    final name = [code, script, country]
        .where((part) => part != null && part.isNotEmpty)
        .join('_');
    final candidates = <String>{
      if (name.isNotEmpty) 'lib/l10n/intl_$name.arb',
      if (script != null && script.isNotEmpty)
        'lib/l10n/intl_${code}_$script.arb',
      if (country != null && country.isNotEmpty)
        'lib/l10n/intl_${code}_$country.arb',
      'lib/l10n/intl_$code.arb',
    };
    for (final path in candidates) {
      try {
        final jsonString = await rootBundle.loadString(path);
        return _parseJson(jsonString);
      } catch (_) {
        continue;
      }
    }
    try {
      final path = 'lib/l10n/intl_$code.arb';
      final jsonString = await rootBundle.loadString(path);
      return _parseJson(jsonString);
    } catch (_) {
      return <String, String>{};
    }
  }

  static Map<String, String> _parseJson(String raw) {
    final Map<String, dynamic> jsonMap =
        json.decode(raw) as Map<String, dynamic>;
    final Map<String, String> values = <String, String>{};
    jsonMap.forEach((key, value) {
      if (!key.startsWith('@') && value is String) {
        values[key] = value;
      }
    });
    return values;
  }

  static Iterable<Locale> _parentLocales(Locale locale) sync* {
    final script = locale.scriptCode;
    final country = locale.countryCode;
    if (script != null && country != null) {
      yield Locale.fromSubtags(
        languageCode: locale.languageCode,
        scriptCode: script,
      );
      yield Locale.fromSubtags(
        languageCode: locale.languageCode,
        countryCode: country,
      );
    } else if (country != null) {
      yield Locale.fromSubtags(
        languageCode: locale.languageCode,
        countryCode: country,
      );
    } else if (script != null) {
      yield Locale.fromSubtags(
        languageCode: locale.languageCode,
        scriptCode: script,
      );
    }
    if (locale.languageCode != 'en') {
      yield Locale(locale.languageCode);
    }
  }

  String tr(String key, [Map<String, String>? params]) {
    var value = _localizedStrings[key] ?? _fallbackStrings[key] ?? key;
    if (params != null) {
      params.forEach((placeholder, replacement) {
        value = value.replaceAll('{$placeholder}', replacement);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((supported) => supported.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
