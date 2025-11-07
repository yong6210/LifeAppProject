import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/journal/journal_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Journal calendar maintains smooth scrolling performance', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = List.generate(60, (index) {
      final date = now.subtract(Duration(days: index));
      return {
        'id': 'entry_$index',
        'date': date.toIso8601String(),
        'mood': index.isEven ? 'Great' : 'Tired',
        'sleepHours': 7.0,
        'energyLevel': index.isEven ? 'Energetic' : 'Low',
        'notes': 'Sample note $index',
      };
    });

    SharedPreferences.setMockInitialValues({
      'journal_entries_v1': jsonEncode(entries),
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: JournalPage())),
    );
    await tester.pumpAndSettle();

    final timings = <ui.FrameTiming>[];
    void captureTimings(List<ui.FrameTiming> captured) {
      timings.addAll(captured);
    }
    tester.binding.addTimingsCallback(captureTimings);

    final listFinder = find.byType(ListView);
    await tester.fling(listFinder, const Offset(0, -600), 1200);
    await tester.pumpAndSettle();
    await tester.fling(listFinder, const Offset(0, 600), 1200);
    await tester.pumpAndSettle();

    tester.binding.removeTimingsCallback(captureTimings);

    final buildAverageMs = timings.isEmpty
        ? 0
        : timings
                  .map((t) => t.buildDuration.inMicroseconds)
                  .fold<int>(0, (sum, value) => sum + value) /
              timings.length /
              1000;
    final rasterAverageMs = timings.isEmpty
        ? 0
        : timings
                  .map((t) => t.rasterDuration.inMicroseconds)
                  .fold<int>(0, (sum, value) => sum + value) /
              timings.length /
              1000;

    // Record to logs for documentation reference.
    // ignore: avoid_print
    print(
      'journal_calendar_perf: build=${buildAverageMs.toStringAsFixed(2)}ms '
      'raster=${rasterAverageMs.toStringAsFixed(2)}ms',
    );

    expect(buildAverageMs, lessThan(16.7));
    expect(rasterAverageMs, lessThan(16.7));
  });
}
