import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:life_app/services/audio/sleep_sound_analyzer.dart';

/// Persists the most recent [SleepSoundSummary] to disk so the home dashboard
/// can surface the latest analysis result even after the app restarts.
class SleepSoundSummaryStore {
  SleepSoundSummaryStore({Future<Directory> Function()? documentsDirBuilder})
    : _documentsDirBuilder =
          documentsDirBuilder ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirBuilder;

  Future<Directory> _ensureBaseDirectory() async {
    final root = await _documentsDirBuilder();
    final dir = Directory(p.join(root.path, 'sleep_summaries'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _latestFile() async {
    final dir = await _ensureBaseDirectory();
    return File(p.join(dir.path, 'latest_summary.json'));
  }

  Future<SleepSoundSummary?> loadLatest() async {
    try {
      final file = await _latestFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      return SleepSoundSummary.fromJson(jsonMap);
    } on FormatException {
      return null;
    } on IOException {
      return null;
    }
  }

  Future<void> saveLatest(SleepSoundSummary summary) async {
    final file = await _latestFile();
    final payload = json.encode(summary.toJson());
    await file.writeAsString(payload);
  }
}

final sleepSoundSummaryStoreProvider = Provider<SleepSoundSummaryStore>(
  (ref) => SleepSoundSummaryStore(),
);
