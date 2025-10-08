import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:life_app/services/db.dart';

/// DB.instance()를 래핑해서 어디서든 동일 인스턴스 사용
final isarProvider = FutureProvider<Isar>((ref) async {
  return await DB.instance();
});
