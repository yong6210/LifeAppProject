import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_app/models/daily_summary_local.dart';

class DailySummaryRemoteDto {
  DailySummaryRemoteDto({
    required this.focusMinutes,
    required this.restMinutes,
    required this.workoutMinutes,
    required this.sleepMinutes,
    required this.updatedAt,
  });

  factory DailySummaryRemoteDto.fromLocal(DailySummaryLocal local) {
    return DailySummaryRemoteDto(
      focusMinutes: local.focusMinutes,
      restMinutes: local.restMinutes,
      workoutMinutes: local.workoutMinutes,
      sleepMinutes: local.sleepMinutes,
      updatedAt: local.updatedAt,
    );
  }

  factory DailySummaryRemoteDto.fromMap(Map<String, dynamic> data) {
    return DailySummaryRemoteDto(
      focusMinutes: (data['focus'] as num?)?.toInt() ?? 0,
      restMinutes: (data['rest'] as num?)?.toInt() ?? 0,
      workoutMinutes: (data['workout'] as num?)?.toInt() ?? 0,
      sleepMinutes: (data['sleep'] as num?)?.toInt() ?? 0,
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final int focusMinutes;
  final int restMinutes;
  final int workoutMinutes;
  final int sleepMinutes;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'focus': focusMinutes,
      'rest': restMinutes,
      'workout': workoutMinutes,
      'sleep': sleepMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
