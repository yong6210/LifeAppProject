import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:life_app/services/sync/offline_sync_queue.dart';

typedef OfflineSyncHandler = Future<void> Function(OfflineSyncAction action);

class OfflineSyncService {
  OfflineSyncService(this._queue);

  final OfflineSyncQueue _queue;
  final Map<OfflineSyncActionKind, OfflineSyncHandler> _handlers = {};
  final _uuid = const Uuid();

  void registerHandler(OfflineSyncActionKind kind, OfflineSyncHandler handler) {
    _handlers[kind] = handler;
  }

  Future<OfflineSyncAction> enqueue({
    required OfflineSyncActionKind kind,
    required Map<String, dynamic> payload,
  }) async {
    final action = OfflineSyncAction(
      id: _uuid.v4(),
      kind: kind,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
    );
    await _queue.enqueue(action);
    return action;
  }

  Future<List<OfflineSyncAction>> pendingActions() {
    return _queue.loadActions();
  }

  Future<void> flushPendingActions() async {
    final actions = await _queue.loadActions();
    for (final action in actions) {
      final handler = _handlers[action.kind];
      if (handler == null) {
        debugPrint(
          'No handler registered for offline sync action ${action.kind.name}',
        );
        continue;
      }
      try {
        await handler(action);
        await _queue.removeById(action.id);
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to process offline sync action: $error\n$stackTrace',
        );
        // keep action for next attempt
      }
    }
  }
}
