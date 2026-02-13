import 'dart:convert';

enum ScheduleRepeatRule { none, daily, weekdays, weekend }

enum ScheduleRoutineType { builtIn, custom }

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.routineId,
    this.routineType = ScheduleRoutineType.builtIn,
    this.repeatRule = ScheduleRepeatRule.none,
    this.isCompleted = false,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      title: json['title'] as String,
      routineId: json['routineId'] as String,
      routineType: ScheduleRoutineType.values.firstWhere(
        (value) => value.name == (json['routineType'] as String? ?? 'builtIn'),
      ),
      repeatRule: ScheduleRepeatRule.values.firstWhere(
        (value) => value.name == (json['repeatRule'] as String? ?? 'none'),
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String routineId;
  final ScheduleRoutineType routineType;
  final ScheduleRepeatRule repeatRule;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? title,
    String? routineId,
    ScheduleRoutineType? routineType,
    ScheduleRepeatRule? repeatRule,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      routineId: routineId ?? this.routineId,
      routineType: routineType ?? this.routineType,
      repeatRule: repeatRule ?? this.repeatRule,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'title': title,
      'routineId': routineId,
      'routineType': routineType.name,
      'repeatRule': repeatRule.name,
      'isCompleted': isCompleted,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CustomRoutine {
  CustomRoutine({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.description,
    this.audioAsset,
    this.segments = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  factory CustomRoutine.fromJson(Map<String, dynamic> json) {
    return CustomRoutine(
      id: json['id'] as String,
      title: json['title'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      description: json['description'] as String?,
      audioAsset: json['audioAsset'] as String?,
      segments: (json['segments'] as List?)
              ?.map(
                (item) => RoutineSegment.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String title;
  final int durationMinutes;
  final String? description;
  final String? audioAsset;
  final List<RoutineSegment> segments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'audioAsset': audioAsset,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RoutineSegment {
  const RoutineSegment({
    required this.label,
    required this.durationMinutes,
    this.audioAsset,
  });

  factory RoutineSegment.fromJson(Map<String, dynamic> json) {
    return RoutineSegment(
      label: json['label'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      audioAsset: json['audioAsset'] as String?,
    );
  }

  final String label;
  final int durationMinutes;
  final String? audioAsset;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'durationMinutes': durationMinutes,
      'audioAsset': audioAsset,
    };
  }
}

String encodeScheduleEntries(List<ScheduleEntry> entries) {
  final data = entries.map((entry) => entry.toJson()).toList();
  return json.encode(data);
}

List<ScheduleEntry> decodeScheduleEntries(String raw) {
  if (raw.trim().isEmpty) return const [];
  final decoded = json.decode(raw) as List<dynamic>;
  return decoded
      .map(
        (item) =>
            ScheduleEntry.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
}

String encodeCustomRoutines(List<CustomRoutine> routines) {
  final data = routines.map((routine) => routine.toJson()).toList();
  return json.encode(data);
}

List<CustomRoutine> decodeCustomRoutines(String raw) {
  if (raw.trim().isEmpty) return const [];
  final decoded = json.decode(raw) as List<dynamic>;
  return decoded
      .map(
        (item) =>
            CustomRoutine.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
}
