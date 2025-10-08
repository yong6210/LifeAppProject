import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// 사용 중인 스키마들
import 'package:life_app/models/change_log.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/models/routine.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/models/settings.dart';

class DB {
  DB._();
  static Isar? _isar;

  /// 앱 전역에서 Isar를 딱 한 번만 오픈
  static Future<Isar> instance() async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        SessionSchema,
        SettingsSchema,
        RoutineSchema,
        DailySummaryLocalSchema,
        ChangeLogSchema,
      ],
      name: 'life_app',
      directory: dir.path,
      inspector: false,
    );
    return _isar!;
  }

  static Future<void> replaceWithBytes(Uint8List bytes) async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'life_app.isar');
    final file = File(dbPath);
    await file.writeAsBytes(bytes, flush: true);
    await instance();
  }
}
