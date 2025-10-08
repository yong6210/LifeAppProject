import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_app/core/firebase/models/daily_summary_remote.dart';
import 'package:life_app/core/firebase/models/settings_remote.dart';
import 'package:life_app/firebase_options.dart';
import 'package:life_app/models/daily_summary_local.dart' as daily_models;
import 'package:life_app/models/settings.dart' as settings_model;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _SmokeApp());
}

class _SmokeApp extends StatefulWidget {
  const _SmokeApp();

  @override
  State<_SmokeApp> createState() => _SmokeAppState();
}

class _SmokeAppState extends State<_SmokeApp> {
  String _status = 'Running staging Firestore smoke test...';
  Map<String, Object?>? _payload;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  @override
  Widget build(BuildContext context) {
    final encoder = const JsonEncoder.withIndent('  ');
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Firestore Smoke Test',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error.toString(),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_payload != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    encoder.convert(_payload),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _run() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final auth = FirebaseAuth.instance;
      final credentials = await auth.signInAnonymously();
      final uid = credentials.user!.uid;

      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now().toUtc();
      final deviceId = 'smoke-${now.millisecondsSinceEpoch}';

      final settings = settings_model.Settings()
        ..deviceId = deviceId
        ..sleepMixerPresetId = 'ocean_waves'
        ..sleepMixerWhiteLevel = 0.25
        ..sleepMixerPinkLevel = 0.55
        ..sleepMixerBrownLevel = 0.20
        ..sleepMinutes = 40
        ..lastMode = 'sleep'
        ..schemaVersion = 2
        ..updatedAt = now;

      final settingsDoc = firestore.doc('users/$uid');
      await settingsDoc.set(
        SettingsRemoteDto.fromSettings(settings).toJson(),
        SetOptions(merge: true),
      );

      await Future<void>.delayed(const Duration(seconds: 3));
      final settingsSnapshot = await settingsDoc.get();

      final summary = daily_models.DailySummaryLocal()
        ..date = DateTime(now.year, now.month, now.day)
        ..deviceId = deviceId
        ..focusMinutes = 0
        ..restMinutes = 0
        ..workoutMinutes = 0
        ..sleepMinutes = 1
        ..updatedAt = now;

      final dateKey = _dateKey(summary.date);
      final summaryDoc = firestore.doc('users/$uid/daily_summaries/$dateKey');
      await summaryDoc.set(
        {
          'date': dateKey,
          'buckets': {
            deviceId: DailySummaryRemoteDto.fromLocal(summary).toJson(),
          },
        },
        SetOptions(merge: true),
      );

      await Future<void>.delayed(const Duration(seconds: 3));
      final summarySnapshot = await summaryDoc.get();
      final summaryData = summarySnapshot.data() ?? <String, Object?>{};
      final buckets = summaryData['buckets'] as Map<String, dynamic>? ?? {};

      final payload = <String, Object?>{
        'uid': uid,
        'deviceId': deviceId,
        'settingsPath': settingsDoc.path,
        'summaryPath': summaryDoc.path,
        'settings': _sanitize(settingsSnapshot.data()),
        'dailySummaryDeviceBucket': _encodeSpecial(buckets[deviceId]),
        'bucketKeys': buckets.keys.toList(),
      };

      debugPrint('SMOKE_RESULT:${jsonEncode(payload, toEncodable: _encodeSpecial)}');

      setState(() {
        _status = 'Smoke test completed successfully';
        _payload = payload;
      });

      await auth.currentUser?.delete();
    } catch (error, stackTrace) {
      debugPrint('SMOKE_ERROR:$error');
      debugPrint(stackTrace.toString());
      setState(() {
        _status = 'Smoke test failed';
        _error = error;
      });
    } finally {
      await Future<void>.delayed(const Duration(seconds: 5));
      SystemNavigator.pop();
    }
  }

  Map<String, Object?>? _sanitize(Map<String, Object?>? input) {
    if (input == null) return null;
    return input.map((key, value) => MapEntry(key, _encodeSpecial(value)));
  }

  Object? _encodeSpecial(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is Map) {
      return value.map((key, dynamic val) => MapEntry(key, _encodeSpecial(val)));
    }
    if (value is List) {
      return value.map(_encodeSpecial).toList();
    }
    return value;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
