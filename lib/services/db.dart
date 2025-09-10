import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session.dart';
import '../models/settings.dart';

class DB {
  static Isar? _isar;

  static Future<Isar> instance() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [SessionSchema, SettingsSchema],
      directory: dir.path,
    );
    return _isar!;
  }
}
