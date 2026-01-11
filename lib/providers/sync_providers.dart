import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/core/firebase/firestore_sync_service.dart';
import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/models/change_log.dart';
import 'package:life_app/repositories/change_log_repository.dart';
import 'package:life_app/repositories/daily_summary_repository.dart';
import 'package:life_app/repositories/settings_repository.dart';

final firestoreSyncServiceProvider = FutureProvider<FirestoreSyncService>((
  ref,
) async {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) {
    throw StateError('Firebase Auth is unavailable.');
  }
  final firestore = FirebaseFirestore.instance;
  final isar = await ref.watch(isarProvider.future);
  final settingsRepo = SettingsRepository(isar);
  final summaryRepo = DailySummaryRepository(isar);
  final changeLogRepo = ChangeLogRepository(isar);
  return FirestoreSyncService(
    auth: auth,
    firestore: firestore,
    settingsRepository: settingsRepo,
    dailySummaryRepository: summaryRepo,
    changeLogRepository: changeLogRepo,
  );
});

class SyncController extends AsyncNotifier<void> {
  Timer? _debounce;
  StreamSubscription<void>? _logSubscription;

  @override
  Future<void> build() async {
    await FirebaseInitializer.ensureInitialized();
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      state = const AsyncData(null);
      return;
    }
    final service = await ref.watch(firestoreSyncServiceProvider.future);
    final isar = await ref.watch(isarProvider.future);

    _logSubscription ??= isar.changeLogs
        .watchLazy(fireImmediately: true)
        .listen((_) {
          _scheduleSync(service);
        });

    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.whenData((user) async {
        if (user == null) {
          _debounce?.cancel();
          return;
        }
        await service.pullInitialData();
        _scheduleSync(service, immediate: true);
      });
    });

    final currentUser = ref.watch(authStateProvider).value;
    if (currentUser != null) {
      scheduleMicrotask(() async {
        await service.pullInitialData();
        _scheduleSync(service, immediate: true);
      });
    }

    ref.onDispose(() {
      _debounce?.cancel();
      _logSubscription?.cancel();
    });

    state = const AsyncData(null);
  }

  void _scheduleSync(FirestoreSyncService service, {bool immediate = false}) {
    _debounce?.cancel();
    final delay = immediate ? Duration.zero : const Duration(seconds: 3);
    _debounce = Timer(delay, () async {
      try {
        await service.syncPendingChanges();
      } catch (_) {
        _debounce = Timer(const Duration(seconds: 10), () {
          _scheduleSync(service);
        });
      }
    });
  }
}

final syncControllerProvider = AsyncNotifierProvider<SyncController, void>(
  SyncController.new,
);
