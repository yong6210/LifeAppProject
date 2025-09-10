import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../services/db.dart';

final isarProvider = FutureProvider<Isar>((ref) async => DB.instance());
