import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:life_app/services/schedule/schedule_models.dart';

class ScheduleStore {
  ScheduleStore({Uuid? uuid, Future<Directory> Function()? documentsDirBuilder})
    : _uuid = uuid ?? const Uuid(),
      _documentsDirBuilder =
          documentsDirBuilder ?? getApplicationDocumentsDirectory;

  final Uuid _uuid;
  final Future<Directory> Function() _documentsDirBuilder;

  Future<File> _entriesFile() async {
    final dir = await _documentsDirBuilder();
    return File(p.join(dir.path, 'schedule_entries.json'));
  }

  Future<File> _routinesFile() async {
    final dir = await _documentsDirBuilder();
    return File(p.join(dir.path, 'custom_routines.json'));
  }

  Future<List<ScheduleEntry>> loadEntries() async {
    final file = await _entriesFile();
    if (!await file.exists()) {
      return const [];
    }
    final raw = await file.readAsString();
    return decodeScheduleEntries(raw);
  }

  Future<void> saveEntries(List<ScheduleEntry> entries) async {
    final file = await _entriesFile();
    await file.writeAsString(encodeScheduleEntries(entries));
  }

  Future<List<CustomRoutine>> loadRoutines() async {
    final file = await _routinesFile();
    if (!await file.exists()) {
      return const [];
    }
    final raw = await file.readAsString();
    return decodeCustomRoutines(raw);
  }

  Future<void> saveRoutines(List<CustomRoutine> routines) async {
    final file = await _routinesFile();
    await file.writeAsString(encodeCustomRoutines(routines));
  }

  String generateId() => _uuid.v4();
}
