import 'dart:math';

import 'package:isar/isar.dart';
import 'package:life_app/models/change_log.dart';
import 'package:life_app/models/settings.dart';

String _generateDeviceId() {
  final rand = Random();
  final millis = DateTime.now().millisecondsSinceEpoch;
  final entropy = List<int>.generate(4, (_) => rand.nextInt(1 << 16));
  final encoded = entropy
      .map((e) => e.toRadixString(36).padLeft(3, '0'))
      .join();
  return 'dev-$millis-$encoded';
}

class SettingsRepository {
  SettingsRepository(this.isar);

  final Isar isar;

  Future<Settings> ensure() async {
    final existing = await isar.settings.get(0);
    if (existing != null) {
      if (existing.deviceId.isEmpty) {
        await isar.writeTxn(() async {
          existing.deviceId = _generateDeviceId();
          existing.updatedAt = DateTime.now().toUtc();
          await isar.settings.put(existing);
        });
      }
      return existing;
    }

    final settings = Settings()
      ..id = 0
      ..deviceId = _generateDeviceId()
      ..createdAt = DateTime.now().toUtc()
      ..updatedAt = DateTime.now().toUtc();

    await isar.writeTxn(() async {
      await isar.settings.put(settings);
      await _insertChangeLog(isar);
    });
    return settings;
  }

  Future<Settings> get() async => ensure();

  Future<void> save(Settings settings) async {
    await isar.writeTxn(() async {
      settings.updatedAt = DateTime.now().toUtc();
      await isar.settings.put(settings);
    });
  }

  Future<void> update(void Function(Settings settings) mutate) async {
    await isar.writeTxn(() async {
      final settings = await isar.settings.get(0) ?? (Settings()..id = 0);
      mutate(settings);
      settings.updatedAt = DateTime.now().toUtc();
      await isar.settings.put(settings);
      await _insertChangeLog(isar);
    });
  }

  Future<void> _insertChangeLog(Isar isar) async {
    await isar.changeLogs.put(
      ChangeLog()
        ..entity = SettingsSchema.name
        ..entityId = 0
        ..action = 'updated'
        ..occurredAt = DateTime.now().toUtc(),
    );
  }
}
