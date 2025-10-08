import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_app/core/firebase/firestore_paths.dart';
import 'package:life_app/core/firebase/models/daily_summary_remote.dart';
import 'package:life_app/core/firebase/models/settings_remote.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/repositories/change_log_repository.dart';
import 'package:life_app/repositories/daily_summary_repository.dart';
import 'package:life_app/repositories/settings_repository.dart';

class FirestoreSyncService {
  FirestoreSyncService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required SettingsRepository settingsRepository,
    required DailySummaryRepository dailySummaryRepository,
    required ChangeLogRepository changeLogRepository,
  }) : _auth = auth,
       _firestore = firestore,
       _settingsRepository = settingsRepository,
       _dailySummaryRepository = dailySummaryRepository,
       _changeLogRepository = changeLogRepository;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SettingsRepository _settingsRepository;
  final DailySummaryRepository _dailySummaryRepository;
  final ChangeLogRepository _changeLogRepository;

  Future<void> pullInitialData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _pullSettings(uid);
    await _pullRecentSummaries(uid);
  }

  Future<void> syncPendingChanges() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final logs = await _changeLogRepository.fetchUnprocessed(limit: 50);
    if (logs.isEmpty) return;

    final processed = <int>[];

    for (final log in logs) {
      try {
        if (log.entity == SettingsSchema.name) {
          await _pushSettings(uid);
          processed.add(log.id);
        } else if (log.entity == DailySummaryLocalSchema.name) {
          await _pushDailySummary(uid, log.entityId);
          processed.add(log.id);
        }
      } catch (error) {
        // Leave log unprocessed for retry
      }
    }

    if (processed.isNotEmpty) {
      await _changeLogRepository.markProcessed(processed);
    }
  }

  Future<void> _pullSettings(String uid) async {
    final doc = await _firestore.doc(FirestorePaths.settingsDoc(uid)).get();
    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    final settings = await _settingsRepository.ensure();
    final dto = SettingsRemoteDto.fromMap(data, settings);

    await _settingsRepository.update((local) {
      dto.applyTo(local);
    });
  }

  Future<void> _pullRecentSummaries(String uid) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));

    final snapshots = await _firestore
        .collection('users/$uid/daily_summaries')
        .where('date', isGreaterThanOrEqualTo: _dateKey(start))
        .get();

    for (final doc in snapshots.docs) {
      final data = doc.data();
      final buckets = data['buckets'] as Map<String, dynamic>?;
      if (buckets == null) continue;

      final settings = await _settingsRepository.ensure();
      final deviceBucket =
          buckets[settings.deviceId] as Map<String, dynamic>? ?? {};
      if (deviceBucket.isEmpty) continue;

      final dto = DailySummaryRemoteDto.fromMap(deviceBucket);
      final local = DailySummaryLocal()
        ..date = _parseDateKey(doc.id)
        ..deviceId = settings.deviceId
        ..focusMinutes = dto.focusMinutes
        ..restMinutes = dto.restMinutes
        ..workoutMinutes = dto.workoutMinutes
        ..sleepMinutes = dto.sleepMinutes
        ..updatedAt = dto.updatedAt;
      await _dailySummaryRepository.upsert(local);
    }
  }

  Future<void> _pushSettings(String uid) async {
    final settings = await _settingsRepository.get();
    final dto = SettingsRemoteDto.fromSettings(settings);
    final doc = _firestore.doc(FirestorePaths.settingsDoc(uid));
    await doc.set(dto.toJson(), SetOptions(merge: true));
  }

  Future<void> _pushDailySummary(String uid, int localId) async {
    final summary = await _dailySummaryRepository.getById(localId);
    if (summary == null) return;

    final settings = await _settingsRepository.get();
    final path = FirestorePaths.dailySummaryDoc(uid, _dateKey(summary.date));
    final doc = _firestore.doc(path);

    final dto = DailySummaryRemoteDto.fromLocal(summary);
    await doc.set({
      'date': _dateKey(summary.date),
      'buckets': {settings.deviceId: dto.toJson()},
    }, SetOptions(merge: true));
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDateKey(String key) {
    final year = int.parse(key.substring(0, 4));
    final month = int.parse(key.substring(4, 6));
    final day = int.parse(key.substring(6, 8));
    return DateTime(year, month, day);
  }
}
