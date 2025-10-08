import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

class RemoteConfigSnapshot {
  const RemoteConfigSnapshot({
    this.paywallVariant,
    this.onboardingVariant,
    this.telemetryDefault,
    this.fetchedAt,
    this.sleepSoundEnabled,
  });

  final String? paywallVariant;
  final String? onboardingVariant;
  final bool? telemetryDefault;
  final DateTime? fetchedAt;
  final bool? sleepSoundEnabled;

  static const empty = RemoteConfigSnapshot();
}

class RemoteConfigService {
  const RemoteConfigService._();

  static Future<RemoteConfigSnapshot> fetch() async {
    if (Firebase.apps.isEmpty) {
      return RemoteConfigSnapshot.empty;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('remote_config')
          .doc('app')
          .get();
      final data = snapshot.data();
      if (data == null) {
        return RemoteConfigSnapshot.empty;
      }
      return RemoteConfigSnapshot(
        paywallVariant: data['paywall_variant'] as String?,
        onboardingVariant: data['onboarding_variant'] as String?,
        telemetryDefault: data['telemetry_default'] as bool?,
        fetchedAt: DateTime.now().toUtc(),
        sleepSoundEnabled: data['sleep_sound_enabled'] as bool?,
      );
    } catch (error, stack) {
      debugPrint('Remote config fetch failed: $error');
      await AnalyticsService.recordError(
        error,
        stack,
        reason: 'remote_config_fetch_failed',
      );
      return RemoteConfigSnapshot.empty;
    }
  }
}
