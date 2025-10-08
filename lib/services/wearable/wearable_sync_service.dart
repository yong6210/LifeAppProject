import 'package:health/health.dart';

/// Lightweight service that demonstrates how HealthKit / Google Fit access
/// will be requested and queried. It keeps the integration scope limited to
/// features we plan to support (sleep, heart-rate, HRV, activity summaries).
class WearableSyncService {
  WearableSyncService({Health? health}) : _health = health ?? Health();

  final Health _health;

  static const _readTypes = <HealthDataType>[
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.STEPS,
  ];

  static const _readPermissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// Configures the plugin. Call once during app boot.
  Future<void> configure() async {
    await _health.configure();
  }

  /// Request read permissions for the predefined set of health metrics.
  Future<bool> requestAuthorization() async {
    final hasPerm = await _health.hasPermissions(_readTypes);
    if (hasPerm == true) {
      return true;
    }
    return _health.requestAuthorization(
      _readTypes,
      permissions: _readPermissions,
    );
  }

  /// Fetches sleep samples between [start] and [end].
  Future<List<HealthDataPoint>> fetchSleepSamples(
    DateTime start,
    DateTime end,
  ) async {
    final points = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: const [HealthDataType.SLEEP_ASLEEP],
    );
    return _health.removeDuplicates(points);
  }

  /// Fetches average heart-rate for the provided window. Returns `null` if no
  /// data is available.
  Future<double?> fetchAverageHeartRate(DateTime start, DateTime end) async {
    final points = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: const [HealthDataType.HEART_RATE],
    );
    if (points.isEmpty) {
      return null;
    }

    final values = points
        .map((point) => point.value)
        .whereType<NumericHealthValue>()
        .map((value) => value.numericValue)
        .toList();

    if (values.isEmpty) {
      return null;
    }

    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  /// Revokes authorization where supported (Health Connect only).
  Future<void> revokePermissions() async {
    await _health.revokePermissions();
  }
}

final wearableSyncService = WearableSyncService();
