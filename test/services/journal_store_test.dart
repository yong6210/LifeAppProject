import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/journal/journal_entry.dart';
import 'package:life_app/services/journal/journal_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JournalStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists and restores latest entry', () async {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'test-entry',
        date: now.subtract(const Duration(hours: 2)),
        mood: 'Calm',
        sleepHours: 7.5,
        energyLevel: 'Balanced',
        notes: 'Fell asleep quickly after stretching.',
      );

      await JournalStore.saveLatest(entry);
      final restored = await JournalStore.loadLatest();

      expect(restored, isNotNull);
      expect(restored!.id, entry.id);
      expect(restored.mood, entry.mood);
      expect(restored.sleepHours, entry.sleepHours);
      expect(restored.energyLevel, entry.energyLevel);
      expect(restored.notes, entry.notes);

      final entries = await JournalStore.loadEntries();
      expect(entries, isNotEmpty);
      expect(entries.first.id, entry.id);
    });

    test('returns null when store empty', () async {
      final restored = await JournalStore.loadLatest();
      expect(restored, isNull);
    });

    test('maintains newest-first ordering and truncates storage', () async {
      const total = 95;
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: total - 1));

      for (var i = 0; i < total; i++) {
        final date = start.add(Duration(days: i));
        final entry = JournalEntry(
          id: 'entry-$i',
          date: date,
          mood: 'Mood $i',
          sleepHours: 6 + (i % 4),
          energyLevel: i.isEven ? 'Balanced' : 'Low',
          notes: 'Note $i',
        );
        await JournalStore.saveEntry(entry);
      }

      final cutoff = now.subtract(const Duration(days: 30));
      final cutoffDate = DateTime(cutoff.year, cutoff.month, cutoff.day);
      final retainedIds = <String>[];
      for (var i = 0; i < total; i++) {
        final entryDate = start.add(Duration(days: i));
        final normalizedDate = DateTime(
          entryDate.year,
          entryDate.month,
          entryDate.day,
        );
        if (!normalizedDate.isBefore(cutoffDate)) {
          retainedIds.add('entry-$i');
        }
      }
      final newestFirstIds = retainedIds.reversed.toList();

      final entries = await JournalStore.loadEntries();
      expect(entries.map((entry) => entry.id), newestFirstIds);

      final limited = await JournalStore.loadEntries(limit: 5);
      final expectedLimited = newestFirstIds.take(5).toList();
      expect(limited.length, expectedLimited.length);
      expect(limited.map((entry) => entry.id), expectedLimited);
    });

    test('deletes entry and updates latest pointer', () async {
      final now = DateTime.now();
      final first = JournalEntry(
        id: 'first',
        date: now.subtract(const Duration(days: 1)),
        mood: 'Bright',
        sleepHours: 7.1,
        energyLevel: 'Balanced',
      );
      final second = JournalEntry(
        id: 'second',
        date: now,
        mood: 'Calm',
        sleepHours: 7.8,
        energyLevel: 'Energetic',
      );

      await JournalStore.saveEntry(first);
      await JournalStore.saveEntry(second);

      var latest = await JournalStore.loadLatest();
      expect(latest?.id, 'second');

      await JournalStore.deleteEntry('second');
      latest = await JournalStore.loadLatest();
      expect(latest?.id, 'first');

      final entries = await JournalStore.loadEntries();
      expect(entries.length, 1);
      expect(entries.single.id, 'first');
    });
  });
}
