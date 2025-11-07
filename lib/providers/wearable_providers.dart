import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/services/wearable/wearable_repository.dart';
import 'package:life_app/services/wearable/wearable_summary_store.dart';

final wearableRepositoryProvider = Provider<WearableRepository>((ref) {
  final repository = _createRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

WearableRepository _createRepository() {
  if (kIsWeb) {
    return MockWearableRepository();
  }
  if (Platform.isIOS || Platform.isAndroid) {
    return HealthWearableRepository();
  }
  return MockWearableRepository();
}

final wearableSummaryStoreProvider = Provider<WearableSummaryStore>(
  (ref) => WearableSummaryStore(),
);

final wearableSummaryProvider = StreamProvider<WearableSummary>((ref) {
  final repository = ref.watch(wearableRepositoryProvider);
  final store = ref.watch(wearableSummaryStoreProvider);

  final controller = StreamController<WearableSummary>.broadcast();
  StreamSubscription<WearableSummary>? subscription;

  Future<void> initialize() async {
    final cached = await store.load();
    if (cached != null) {
      controller.add(cached);
    }

    subscription = repository.watchTodaySummary().listen((summary) {
      controller.add(summary);
      unawaited(_persistSummary(store, summary));
    });
  }

  unawaited(initialize());

  ref.onDispose(() async {
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

Future<void> _persistSummary(
  WearableSummaryStore store,
  WearableSummary summary,
) async {
  try {
    await store.save(summary);
  } catch (_) {
    // Ignore persistence failures; a future sync will retry.
  }
}
