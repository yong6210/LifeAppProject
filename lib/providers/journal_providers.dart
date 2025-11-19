import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/features/journal/journal_entry.dart';
import 'package:life_app/services/journal/journal_reminder_service.dart';
import 'package:life_app/services/journal/journal_store.dart';
import 'package:life_app/services/journal/life_buddy_comment_service.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';

class JournalEntriesNotifier extends AsyncNotifier<List<JournalEntry>> {
  static const Duration _freeRetention = Duration(days: 30);
  static const Duration _premiumRetention = Duration(days: 365);

  @override
  Future<List<JournalEntry>> build() async {
    return _loadEntries();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadEntries);
  }

  Future<void> addEntry(JournalEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final retention = _currentRetention(listen: false);
      await JournalStore.saveEntry(entry, retention: retention);
      return _loadEntries();
    });
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final retention = _currentRetention(listen: false);
      await JournalStore.deleteEntry(entry.id, retention: retention);
      return _loadEntries();
    });
  }

  Future<List<JournalEntry>> _loadEntries() async {
    final retention = _currentRetention();
    final entries = await JournalStore.loadEntries(retention: retention);
    entries.sort((a, b) => b.date.compareTo(a.date));

    final cutoff = DateTime.now().subtract(retention);
    final cutoffDate = DateUtils.dateOnly(cutoff);

    return entries
        .where((entry) => !DateUtils.dateOnly(entry.date).isBefore(cutoffDate))
        .toList(growable: false);
  }

  Duration _currentRetention({bool listen = true}) {
    final premium = listen
        ? ref.watch(premiumStatusProvider.select((status) => status.isPremium))
        : ref.read(premiumStatusProvider).isPremium;
    return premium ? _premiumRetention : _freeRetention;
  }
}

final journalEntriesProvider =
    AsyncNotifierProvider<JournalEntriesNotifier, List<JournalEntry>>(
      JournalEntriesNotifier.new,
    );

final latestJournalEntryProvider = FutureProvider<JournalEntry?>((ref) async {
  final entries = await ref.watch(journalEntriesProvider.future);
  return entries.isNotEmpty ? entries.first : null;
});

final journalSummaryProvider = FutureProvider<JournalSummary?>((ref) async {
  final entries = await ref.watch(journalEntriesProvider.future);
  if (entries.isEmpty) return null;
  return JournalSummary.fromEntries(entries);
});

final journalReminderProvider = FutureProvider<JournalReminderSettings>((
  ref,
) async {
  return JournalReminderService.load();
});

final journalBuddyCommentProvider = FutureProvider<LifeBuddyComment?>((
  ref,
) async {
  final entries = await ref.watch(journalEntriesProvider.future);
  const engine = LifeBuddyCommentEngine();
  return engine.generate(entries);
});

class JournalSummary {
  const JournalSummary({
    required this.averageSleepHours,
    required this.entriesThisWeek,
    required this.streakDays,
    required this.latestEntry,
    required this.restorativeNights,
    required this.sleepConsistencyScore,
    this.commonMood,
    this.dominantEnergy,
  });

  final double averageSleepHours;
  final int entriesThisWeek;
  final int streakDays;
  final JournalEntry latestEntry;
  final int restorativeNights;
  final double sleepConsistencyScore;
  final String? commonMood;
  final String? dominantEnergy;

  factory JournalSummary.fromEntries(List<JournalEntry> entries) {
    final now = DateTime.now();
    final weekCutoff = now.subtract(const Duration(days: 7));
    final weeklyEntries = entries
        .where((entry) => !entry.date.isBefore(weekCutoff))
        .toList(growable: false);
    final sample = weeklyEntries.isNotEmpty ? weeklyEntries : entries;

    final averageSleep =
        sample.fold<double>(0, (sum, entry) => sum + entry.sleepHours) /
        sample.length;

    final restorativeNights =
        sample.where((entry) => entry.sleepHours >= 7).length;

    final sleepValues = sample.map((entry) => entry.sleepHours).toList();
    var sleepConsistencyScore = 0.0;
    if (sleepValues.isNotEmpty && averageSleep > 0) {
      if (sleepValues.length == 1) {
        sleepConsistencyScore = 100;
      } else {
        final mean = averageSleep;
        final variance = sleepValues.fold<double>(0, (sum, value) {
          final delta = value - mean;
          return sum + delta * delta;
        }) /
            sleepValues.length;
        final stdDeviation = math.sqrt(variance);
        final normalized = (1 - (stdDeviation / mean)).clamp(0.0, 1.0);
        sleepConsistencyScore = (normalized * 100).roundToDouble();
      }
    }

    final weeklyDayCount = weeklyEntries
        .map((entry) => DateUtils.dateOnly(entry.date))
        .toSet()
        .length;
    final sampleDayCount = sample
        .map((entry) => DateUtils.dateOnly(entry.date))
        .toSet()
        .length;

    final moodCounts = <String, int>{};
    final energyCounts = <String, int>{};
    for (final entry in sample) {
      final mood = entry.mood.trim();
      if (mood.isNotEmpty) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
      final energy = entry.energyLevel?.trim();
      if (energy != null && energy.isNotEmpty) {
        energyCounts[energy] = (energyCounts[energy] ?? 0) + 1;
      }
    }

    String? topMood;
    if (moodCounts.isNotEmpty) {
      topMood = moodCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    String? dominantEnergy;
    if (energyCounts.isNotEmpty) {
      dominantEnergy = energyCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final streak = _computeStreak(entries);

    return JournalSummary(
      averageSleepHours: averageSleep,
      entriesThisWeek: weeklyEntries.isNotEmpty
          ? weeklyDayCount
          : sampleDayCount,
      streakDays: streak,
      latestEntry: entries.first,
      restorativeNights: restorativeNights,
      sleepConsistencyScore: sleepConsistencyScore,
      commonMood: topMood,
      dominantEnergy: dominantEnergy,
    );
  }

  static int _computeStreak(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    final uniqueDates =
        entries.map((entry) => DateUtils.dateOnly(entry.date)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    var streak = 1;
    for (var i = 1; i < uniqueDates.length; i++) {
      final previous = uniqueDates[i - 1];
      final current = uniqueDates[i];
      final gap = previous.difference(current).inDays;
      if (gap == 1) {
        streak++;
      } else if (gap > 1) {
        break;
      }
    }
    return streak;
  }
}
