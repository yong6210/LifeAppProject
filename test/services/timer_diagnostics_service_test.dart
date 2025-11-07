import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';

void main() {
  group('TimerDiagnosticsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    TimerAccuracySample buildSample({required String id, required int skew}) {
      return TimerAccuracySample(
        recordedAt: DateTime.utc(2025, 1, 1, 0, 0).add(Duration(minutes: skew)),
        mode: 'focus',
        segmentId: id,
        segmentLabel: 'Segment $id',
        skewMs: skew,
      );
    }

    test('stores and truncates to max samples', () async {
      final service = await TimerDiagnosticsService.create();

      for (var i = 0; i < 60; i++) {
        await service.appendAccuracySample(buildSample(id: 'seg_$i', skew: i));
      }

      final samples = await service.loadAccuracySamples();
      expect(samples.length, 50);
      // Most recent sample should be first.
      expect(samples.first.segmentId, 'seg_59');
      // Oldest retained should be seg_10.
      expect(samples.last.segmentId, 'seg_10');
    });

    test('exports CSV with header and rows', () async {
      final service = await TimerDiagnosticsService.create();
      await service.appendAccuracySample(buildSample(id: 'seg_a', skew: 10));
      final csv = await service.exportAccuracySamplesAsCsv();
      expect(
        csv,
        startsWith('recorded_at_utc,mode,segment_id,segment_label,skew_ms'),
      );
      expect(csv.trim().split('\n').length, 2);
      expect(csv.contains('seg_a'), isTrue);
    });

    test('clear removes stored samples', () async {
      final service = await TimerDiagnosticsService.create();
      await service.appendAccuracySample(buildSample(id: 'seg_clear', skew: 5));
      await service.clearAccuracySamples();
      final samples = await service.loadAccuracySamples();
      expect(samples, isEmpty);
    });
  });
}
