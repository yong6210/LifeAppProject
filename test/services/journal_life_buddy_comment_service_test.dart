import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/features/journal/journal_entry.dart';
import 'package:life_app/services/journal/life_buddy_comment_service.dart';

void main() {
  final engine = const LifeBuddyCommentEngine();

  JournalEntry entry({
    required String id,
    required String mood,
    String? notes,
    DateTime? date,
  }) {
    return JournalEntry(
      id: id,
      date: date ?? DateTime.now(),
      mood: mood,
      sleepHours: 7,
      energyLevel: null,
      notes: notes,
    );
  }

  test('returns first entry encouragement', () {
    final result = engine.generate([entry(id: '1', mood: '좋아요')]);
    expect(result?.ruleId, 'rule_32_first_entry');
  });

  test('detects overtime keyword', () {
    final result = engine.generate([
      entry(id: '1', mood: '피곤해요', notes: '오늘 야근 때문에 너무 피곤해'),
      entry(
        id: '0',
        mood: '무기력해요',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
    expect(result?.ruleId, 'rule_25_overtime');
  });

  test('detects consecutive positive moods', () {
    final now = DateTime.now();
    final result = engine.generate([
      entry(id: 'a', mood: '설레요', date: now),
      entry(id: 'b', mood: '뿌듯해요', date: now.subtract(const Duration(days: 1))),
      entry(id: 'c', mood: '좋아요', date: now.subtract(const Duration(days: 2))),
    ]);
    expect(result?.ruleId, 'rule_6_three_positive');
  });

  test('falls back to generic message when no rule matches', () {
    final result = engine.generate([
      entry(id: '1', mood: '중립'),
      entry(
        id: '0',
        mood: '중립',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
    expect(result, isNotNull);
  });
}
