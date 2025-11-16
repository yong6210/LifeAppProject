import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_app/services/sync/offline_sync_queue.dart';
import 'package:life_app/services/sync/offline_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSyncQueue', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('enqueue persists actions and preserves order', () async {
      final queue = await OfflineSyncQueue.create();
      final service = OfflineSyncService(queue);

      await service.enqueue(
        kind: OfflineSyncActionKind.characterState,
        payload: {'level': 1},
      );
      await service.enqueue(
        kind: OfflineSyncActionKind.decorState,
        payload: {'itemId': 'lamp'},
      );

      final actions = await queue.loadActions();
      expect(actions.length, 2);
      expect(actions.first.kind, OfflineSyncActionKind.characterState);
      expect(actions.last.kind, OfflineSyncActionKind.decorState);
    });
  });

  group('OfflineSyncService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('flushPendingActions executes handlers and clears queue', () async {
      final queue = await OfflineSyncQueue.create();
      final service = OfflineSyncService(queue);

      var characterHandled = 0;
      var decorHandled = 0;

      service.registerHandler(OfflineSyncActionKind.characterState, (
        action,
      ) async {
        characterHandled += action.payload['delta'] as int;
      });
      service.registerHandler(OfflineSyncActionKind.decorState, (action) async {
        decorHandled += 1;
      });

      await service.enqueue(
        kind: OfflineSyncActionKind.characterState,
        payload: {'delta': 5},
      );
      await service.enqueue(
        kind: OfflineSyncActionKind.decorState,
        payload: {'id': 'plant'},
      );

      await service.flushPendingActions();

      expect(characterHandled, 5);
      expect(decorHandled, 1);

      final remaining = await queue.loadActions();
      expect(remaining, isEmpty);
    });

    test('flushPendingActions keeps items when handler throws', () async {
      final queue = await OfflineSyncQueue.create();
      final service = OfflineSyncService(queue);

      // Register a handler that throws an exception
      service.registerHandler(OfflineSyncActionKind.characterState, (
        action,
      ) async {
        throw Exception('Simulated failure');
      });

      await service.enqueue(
        kind: OfflineSyncActionKind.characterState,
        payload: {'delta': 1},
      );

      // The flush should catch the exception and keep the item in queue
      await service.flushPendingActions();

      // Verify the item remains in the queue after failed processing
      final remaining = await queue.loadActions();
      expect(remaining.length, 1);
      expect(remaining.first.kind, OfflineSyncActionKind.characterState);
    });
  });
}
