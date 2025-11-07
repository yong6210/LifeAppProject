import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/journal/journal_entry.dart';

class JournalStore {
  JournalStore._();

  static const _keyLatestEntry = 'journal_latest_entry_v1';
  static const _keyEntries = 'journal_entries_v1';

  /// Maximum number of entries kept locally to prevent unbounded growth.
  static const int _maxEntries = 90;
  static const Duration _defaultRetention = Duration(days: 30);

  static Future<void> saveLatest(JournalEntry entry) async {
    await saveEntry(entry);
  }

  static Future<void> saveEntry(
    JournalEntry entry, {
    Duration? retention,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _loadRawEntries(prefs);
    final serialized = entry.toJson();

    entries.removeWhere((raw) => raw['id'] == entry.id);
    entries.insert(0, serialized);

    final normalized = _normalize(
      entries,
      retention ?? _defaultRetention,
    );
    await _persistEntries(prefs, normalized);
  }

  static Future<JournalEntry?> loadLatest() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await loadEntries(limit: 1);
    if (entries.isNotEmpty) {
      return entries.first;
    }

    final raw = prefs.getString(_keyLatestEntry);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return JournalEntry.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<List<JournalEntry>> loadEntries({
    int? limit,
    Duration? retention,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final retentionWindow = retention ?? _defaultRetention;
    try {
      final rawEntries = _normalize(
        await _loadRawEntries(prefs),
        retentionWindow,
      );
      await _persistEntries(prefs, rawEntries);
      final entries = rawEntries
          .map((raw) => JournalEntry.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
      if (limit != null && entries.length > limit) {
        return entries.sublist(0, limit);
      }
      return entries;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> deleteEntry(
    String id, {
    Duration? retention,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = await _loadRawEntries(prefs)
      ..removeWhere((raw) => raw['id'] == id);
    final normalized = _normalize(
      rawEntries,
      retention ?? _defaultRetention,
    );
    await _persistEntries(prefs, normalized);
  }

  static Future<List<Map<String, dynamic>>> _loadRawEntries(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_keyEntries);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (rawEntry) =>
                  rawEntry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
      }
    } catch (_) {
      // Ignore corrupted payloads and fall back to empty list.
    }
    return <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> _normalize(
    List<Map<String, dynamic>> entries,
    Duration retention,
  ) {
    final cutoff = DateTime.now().subtract(retention);
    final cutoffDate = DateTime(cutoff.year, cutoff.month, cutoff.day);
    final filtered = <Map<String, dynamic>>[];

    for (final raw in entries) {
      final dateString = raw['date']?.toString();
      final parsed = DateTime.tryParse(dateString ?? '');
      if (parsed == null) {
        continue;
      }
      final entryDate = DateTime(parsed.year, parsed.month, parsed.day);
      if (entryDate.isBefore(cutoffDate)) {
        continue;
      }
      filtered.add(raw);
      if (filtered.length >= _maxEntries) {
        break;
      }
    }
    return filtered;
  }

  static Future<void> _persistEntries(
    SharedPreferences prefs,
    List<Map<String, dynamic>> entries,
  ) async {
    if (entries.isEmpty) {
      prefs
        ..remove(_keyEntries)
        ..remove(_keyLatestEntry);
      return;
    }

    await prefs.setString(_keyEntries, jsonEncode(entries));
    await prefs.setString(_keyLatestEntry, jsonEncode(entries.first));
  }
}
