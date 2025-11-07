import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:life_app/services/wearable/wearable_repository.dart';

/// Persists the last known [WearableSummary] to disk so that dashboards can
/// render cached insights before a fresh sync completes.
class WearableSummaryStore {
  WearableSummaryStore({Future<Directory> Function()? documentsDirBuilder})
    : _documentsDirBuilder =
          documentsDirBuilder ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirBuilder;

  Future<Directory> _ensureDirectory() async {
    final root = await _documentsDirBuilder();
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<File> _summaryFile() async {
    final dir = await _ensureDirectory();
    return File(p.join(dir.path, 'wearable_summary.json'));
  }

  Future<WearableSummary?> load() async {
    try {
      final file = await _summaryFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      return WearableSummary.fromJson(jsonMap);
    } on FormatException {
      return null;
    } on IOException {
      return null;
    }
  }

  Future<void> save(WearableSummary summary) async {
    final file = await _summaryFile();
    final payload = json.encode(summary.toJson());
    await file.writeAsString(payload, flush: true);
  }

  Future<void> clear() async {
    final file = await _summaryFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
