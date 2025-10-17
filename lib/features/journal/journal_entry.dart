import 'package:equatable/equatable.dart';

/// Simple in-memory representation of a journal entry.
class JournalEntry extends Equatable {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.sleepHours,
    this.energyLevel,
    this.notes,
  });

  final String id;
  final DateTime date;
  final String mood;
  final double sleepHours;
  final String? energyLevel;
  final String? notes;

  JournalEntry copyWith({
    DateTime? date,
    String? mood,
    double? sleepHours,
    String? energyLevel,
    String? notes,
  }) {
    return JournalEntry(
      id: id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      sleepHours: sleepHours ?? this.sleepHours,
      energyLevel: energyLevel ?? this.energyLevel,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, date, mood, sleepHours, energyLevel, notes];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'sleepHours': sleepHours,
      'energyLevel': energyLevel,
      'notes': notes,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      mood: json['mood'] as String? ?? '',
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
      energyLevel: json['energyLevel'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
