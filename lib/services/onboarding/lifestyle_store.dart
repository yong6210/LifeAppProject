import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LifestylePreferenceSnapshot {
  const LifestylePreferenceSnapshot({
    required this.preferences,
    required this.version,
    required this.updatedAt,
  });

  final List<String> preferences;
  final int version;
  final DateTime? updatedAt;

  static LifestylePreferenceSnapshot empty() =>
      const LifestylePreferenceSnapshot(
        preferences: <String>[],
        version: 1,
        updatedAt: null,
      );

  Map<String, dynamic> toJson() {
    return {
      'preferences': preferences,
      'version': version,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LifestylePreferenceSnapshot.fromJson(Map<String, dynamic> json) {
    final rawPrefs = json['preferences'];
    final prefs = rawPrefs is List
        ? rawPrefs.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    final version = json['version'] as int? ?? 1;
    final updatedRaw = json['updatedAt'] as String?;
    final updatedAt = updatedRaw == null ? null : DateTime.tryParse(updatedRaw);

    return LifestylePreferenceSnapshot(
      preferences: prefs,
      version: version,
      updatedAt: updatedAt,
    );
  }
}

class LifestylePreferenceStore {
  LifestylePreferenceStore._();

  static const _key = 'lifestyle_preferences_v1';

  static Future<LifestylePreferenceSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return LifestylePreferenceSnapshot.empty();
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LifestylePreferenceSnapshot.fromJson(map);
    } catch (_) {
      return LifestylePreferenceSnapshot.empty();
    }
  }

  static Future<void> save(List<String> preferences, {int version = 1}) async {
    final snapshot = LifestylePreferenceSnapshot(
      preferences: preferences,
      version: version,
      updatedAt: DateTime.now().toUtc(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }
}
