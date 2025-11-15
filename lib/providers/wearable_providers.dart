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
    // TODO(wearable-web): Replace the mock repository with a real web
    // integration that syncs wearable data from the user's account.
    // 현재는 웹 환경에서 웨어러블 요약을 DB/로컬 스토리지와 연동하지 못해
    // 데모 데이터를 반환하는 MockWearableRepository만 사용합니다.
    return MockWearableRepository();
  }
  if (Platform.isIOS || Platform.isAndroid) {
    return HealthWearableRepository();
  }
  // TODO(wearable-desktop): Implement desktop wearable support or disable the
  // feature gracefully when no device link is available.
  // 지금은 데스크톱 플랫폼에서도 실제 연동 없이 목업 리포지토리를 반환해
  // 저장된 사용자 데이터와 동기화되지 않습니다.
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
