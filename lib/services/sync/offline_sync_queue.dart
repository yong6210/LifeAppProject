import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OfflineSyncActionKind { characterState, decorState }

class OfflineSyncAction {
  OfflineSyncAction({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final OfflineSyncActionKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OfflineSyncAction.fromJson(Map<String, dynamic> json) {
    final kindName =
        json['kind'] as String? ?? OfflineSyncActionKind.characterState.name;
    return OfflineSyncAction(
      id: json['id'] as String,
      kind: OfflineSyncActionKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => OfflineSyncActionKind.characterState,
      ),
      payload:
          (json['payload'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class OfflineSyncQueue {
  OfflineSyncQueue(this._prefs);

  static const _storageKey = 'offline_sync_queue_v1';

  final SharedPreferences _prefs;

  static Future<OfflineSyncQueue> create() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineSyncQueue(prefs);
  }

  Future<List<OfflineSyncAction>> loadActions() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <OfflineSyncAction>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final actions =
          decoded
              .map(
                (item) => OfflineSyncAction.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return actions;
    } catch (error) {
      debugPrint('Failed to parse offline sync queue: $error');
      return const <OfflineSyncAction>[];
    }
  }

  Future<void> enqueue(OfflineSyncAction action) async {
    final actions = await loadActions();
    final updated = [...actions, action];
    await _persist(updated);
  }

  Future<void> removeById(String id) async {
    final actions = await loadActions();
    final updated = actions.where((action) => action.id != id).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<OfflineSyncAction> actions) async {
    final encoded = jsonEncode(
      actions.map((action) => action.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, encoded);
  }
}
