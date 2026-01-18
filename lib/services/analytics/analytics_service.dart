import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Lightweight consent container for analytics and diagnostics collection.
class AnalyticsConsent {
  const AnalyticsConsent({
    required this.analytics,
    required this.crashlytics,
    required this.performance,
  });

  const AnalyticsConsent.disabled()
    : analytics = false,
      crashlytics = false,
      performance = false;

  final bool analytics;
  final bool crashlytics;
  final bool performance;

  AnalyticsConsent copyWith({
    bool? analytics,
    bool? crashlytics,
    bool? performance,
  }) {
    return AnalyticsConsent(
      analytics: analytics ?? this.analytics,
      crashlytics: crashlytics ?? this.crashlytics,
      performance: performance ?? this.performance,
    );
  }
}

/// Centralised analytics facade to keep instrumentation code consistent.
class AnalyticsService {
  AnalyticsService._();

  static const bool _defaultTelemetry = bool.fromEnvironment(
    'LIFEAPP_TELEMETRY_DEFAULT',
    defaultValue: false,
  );

  static bool _initialized = false;
  static AnalyticsConsent _consent = const AnalyticsConsent.disabled();
  static FirebaseAnalytics? _analytics;

  /// Queued events logged before Firebase initialises successfully.
  static final List<_PendingEvent> _pendingEvents = <_PendingEvent>[];
  static void Function(String, Map<String, Object?> parameters)? _testObserver;

  /// Allows tests to observe analytics traffic without touching Firebase.
  @visibleForTesting
  static void setTestObserver(
    void Function(String, Map<String, Object?> parameters)? observer,
  ) {
    _testObserver = observer;
  }

  @visibleForTesting
  static void setTestConsent(AnalyticsConsent consent) {
    _consent = consent;
  }

  /// Initializes Firebase Analytics/Crashlytics hooks. Call once on app start.
  static Future<void> init({AnalyticsConsent? initialConsent}) async {
    if (_initialized) return;
    if (!_isSupportedPlatform()) {
      _initialized = true;
      return;
    }

    if (Firebase.apps.isEmpty) {
      // Firebase failed to initialise; skip analytics.
      return;
    }

    _analytics = FirebaseAnalytics.instance;
    _consent =
        initialConsent ??
        const AnalyticsConsent(
          analytics: _defaultTelemetry,
          crashlytics: _defaultTelemetry,
          performance: _defaultTelemetry,
        );

    await _applyConsent();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      unawaited(recordFlutterError(details));
    };

    _initialized = true;

    // Flush any events logged before initialisation completed.
    while (_pendingEvents.isNotEmpty) {
      final event = _pendingEvents.removeAt(0);
      unawaited(logEvent(event.name, event.parameters));
    }
  }

  static bool _isSupportedPlatform() {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static AnalyticsConsent get consent => _consent;

  /// Updates telemetry consent; call whenever user preferences change.
  static Future<void> updateConsent(AnalyticsConsent consent) async {
    _consent = consent;
    await _applyConsent();
  }

  static Future<void> _applyConsent() async {
    try {
      await _analytics?.setAnalyticsCollectionEnabled(_consent.analytics);
    } catch (error, stack) {
      debugPrint('Analytics consent update failed (analytics): $error');
      if (_consent.crashlytics) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            reason: 'setAnalyticsCollectionEnabled failed',
            fatal: false,
          ),
        );
      }
    }

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        _consent.crashlytics,
      );
    } catch (error) {
      debugPrint('Analytics consent update failed (crashlytics): $error');
    }
  }

  /// Logs an analytics event respecting consent and Firebase availability.
  static Future<void> logEvent(
    String name, [
    Map<String, Object?> parameters = const <String, Object?>{},
  ]) async {
    _testObserver?.call(name, parameters);
    if (!_consent.analytics || name.trim().isEmpty) {
      return;
    }
    if (!_initialized || _analytics == null) {
      _pendingEvents.add(_PendingEvent(name, parameters));
      return;
    }
    try {
      final sanitized = _sanitizeParameters(parameters);
      await _analytics!.logEvent(name: name, parameters: sanitized);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Failed to log event $name: $error');
      }
      if (_consent.crashlytics) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          reason: 'Analytics logEvent failed for $name',
          fatal: false,
        );
      }
    }
  }

  static Future<void> setUserProperty(String name, String value) async {
    if (!_consent.analytics || name.trim().isEmpty) return;
    if (!_initialized || _analytics == null) {
      return;
    }
    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Failed to set user property $name: $error');
      }
      if (_consent.crashlytics) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          reason: 'Analytics setUserProperty failed for $name',
          fatal: false,
        );
      }
    }
  }

  /// Records Flutter framework errors honoring crash reporting consent.
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_consent.crashlytics) return;
    await FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  /// Records arbitrary errors such as those caught in runZonedGuarded.
  static Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_consent.crashlytics) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }

  /// Associates the current Firebase user identifier with analytics & crashlytics.
  static Future<void> setUserId(String? uid, {bool isAnonymous = false}) async {
    if (_analytics != null && _consent.analytics) {
      if (uid == null) {
        await _analytics!.setUserId(id: null);
      } else {
        await _analytics!.setUserId(id: uid);
        await _analytics!.setUserProperty(
          name: 'user_type',
          value: isAnonymous ? 'anonymous' : 'authenticated',
        );
      }
    }
    if (_consent.crashlytics) {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? 'guest');
    }
  }

  /// Convenience helper for timing operations without Firebase Performance.
  static Future<T> traceAsync<T>(
    String traceName,
    Future<T> Function() runner,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await runner();
    } finally {
      stopwatch.stop();
      await logEvent('perf_trace', {
        'trace': traceName,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
    }
  }

  static Map<String, Object> _sanitizeParameters(
    Map<String, Object?> parameters,
  ) {
    final Map<String, Object> sanitized = <String, Object>{};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is num || value is String || value is bool) {
        sanitized[key] = value;
      } else {
        sanitized[key] = value.toString();
      }
    });
    return sanitized;
  }
}

class _PendingEvent {
  _PendingEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object?> parameters;
}
