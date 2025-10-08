import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';

TimerAccuracySample _sample({required int skewMs}) {
  return TimerAccuracySample(
    recordedAt: DateTime.utc(2025, 1, 1),
    mode: 'focus',
    segmentId: 'seg$skewMs',
    segmentLabel: 'Segment',
    skewMs: skewMs,
  );
}

void main() {
  group('computeDiagnosticsStats', () {
    test('returns zeroed stats for empty list', () {
      final stats = computeDiagnosticsStats(const <TimerAccuracySample>[]);
      expect(stats.count, 0);
      expect(stats.averageSkewMs, 0);
      expect(stats.maxDeviationMs, 0);
      expect(stats.withinTargetPercent, 0);
    });

    test('calculates average, max deviation, and within target percent', () {
      final stats = computeDiagnosticsStats([
        _sample(skewMs: 500),
        _sample(skewMs: -1000),
        _sample(skewMs: 120000),
      ]);

      expect(stats.count, 3);
      expect(stats.averageSkewMs, (500 - 1000 + 120000) / 3);
      expect(stats.maxDeviationMs, 120000);
      expect(stats.withinTargetPercent, closeTo(66.666, 0.01));
    });
  });
}
