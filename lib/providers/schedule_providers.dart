import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/services/schedule/schedule_models.dart';
import 'package:life_app/services/schedule/schedule_store.dart';

class ScheduleState {
  ScheduleState({
    required this.entries,
    required this.routines,
    this.isLoading = false,
    this.error,
  });

  factory ScheduleState.initial() =>
      ScheduleState(entries: const [], routines: const [], isLoading: true);

  final List<ScheduleEntry> entries;
  final List<CustomRoutine> routines;
  final bool isLoading;
  final Object? error;

  ScheduleState copyWith({
    List<ScheduleEntry>? entries,
    List<CustomRoutine>? routines,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return ScheduleState(
      entries: entries ?? this.entries,
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ScheduleController extends Notifier<ScheduleState> {
  late final ScheduleStore _store;

  @override
  ScheduleState build() {
    _store = ref.watch(scheduleStoreProvider);
    Future<void>.microtask(_load);
    return ScheduleState.initial();
  }

  Future<void> _load() async {
    try {
      final entries = await _store.loadEntries();
      final routines = await _store.loadRoutines();
      state = state.copyWith(
        entries: entries..sort((a, b) => a.startTime.compareTo(b.startTime)),
        routines: routines,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> refresh() async => _load();

  Future<void> addOrUpdateEntry(ScheduleEntry entry) async {
    final entries = [...state.entries];
    final existingIndex = entries.indexWhere((item) => item.id == entry.id);
    if (existingIndex >= 0) {
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));
    state = state.copyWith(entries: entries, isLoading: true);
    await _store.saveEntries(entries);
    state = state.copyWith(
      entries: entries,
      isLoading: false,
      clearError: true,
    );
  }

  Future<void> deleteEntry(String id) async {
    final entries = state.entries.where((entry) => entry.id != id).toList();
    state = state.copyWith(entries: entries, isLoading: true);
    await _store.saveEntries(entries);
    state = state.copyWith(
      entries: entries,
      isLoading: false,
      clearError: true,
    );
  }

  Future<void> addOrUpdateRoutine(CustomRoutine routine) async {
    final routines = [...state.routines];
    final index = routines.indexWhere((item) => item.id == routine.id);
    if (index >= 0) {
      routines[index] = routine;
    } else {
      routines.add(routine);
    }
    state = state.copyWith(routines: routines, isLoading: true);
    await _store.saveRoutines(routines);
    state = state.copyWith(
      routines: routines,
      isLoading: false,
      clearError: true,
    );
  }

  Future<void> deleteRoutine(String id) async {
    final routines = state.routines
        .where((routine) => routine.id != id)
        .toList();
    state = state.copyWith(routines: routines, isLoading: true);
    await _store.saveRoutines(routines);
    state = state.copyWith(
      routines: routines,
      isLoading: false,
      clearError: true,
    );
  }
}

final scheduleStoreProvider = Provider<ScheduleStore>((ref) {
  return ScheduleStore();
});

final scheduleControllerProvider =
    NotifierProvider<ScheduleController, ScheduleState>(ScheduleController.new);
