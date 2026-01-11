import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:life_app/core/subscriptions/revenuecat_keys.dart';

/// Resolves the appropriate RevenueCat SDK key for the current platform.
///
/// Precedence:
/// 1. `--dart-define` / environment value (see [RevenueCatKeys]).
/// 2. `assets/config/revenuecat_keys.json` values (kept outside VCS or updated locally).
/// 3. `null` when no usable key is configured.
class RevenueCatKeyStore {
  RevenueCatKeyStore._();

  static const _assetPath = 'assets/config/revenuecat_keys.json';
  static Map<String, String>? _cachedKeys;
  static bool _loadAttempted = false;

  static bool _isPlaceholder(String? value) {
    if (value == null) return true;
    if (value.isEmpty) return true;
    return value.startsWith('REPLACE_WITH');
  }

  static Future<void> _ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final raw = jsonDecode(jsonString) as Map<String, dynamic>;
      _cachedKeys = raw.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    } catch (error) {
      // Asset missing or malformed; silently fall back to environment values.
      debugPrint('RevenueCatKeyStore: unable to load $_assetPath ($error)');
      _cachedKeys = const {};
    }
  }

  static Future<String?> androidKey() async {
    const envKey = RevenueCatKeys.androidKey;
    if (!_isPlaceholder(envKey)) {
      return envKey;
    }
    await _ensureLoaded();
    final assetKey = _cachedKeys?['android'] ?? '';
    return _isPlaceholder(assetKey) ? null : assetKey;
  }

  static Future<String?> iosKey() async {
    const envKey = RevenueCatKeys.iosKey;
    if (!_isPlaceholder(envKey)) {
      return envKey;
    }
    await _ensureLoaded();
    final assetKey = _cachedKeys?['ios'] ?? '';
    return _isPlaceholder(assetKey) ? null : assetKey;
  }
}
