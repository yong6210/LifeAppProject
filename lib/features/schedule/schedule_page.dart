import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/schedule_providers.dart';
import 'package:life_app/services/schedule/schedule_models.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleControllerProvider);
    final l10n = context.l10n;
    final entries = scheduleState.entries;
    final grouped = _groupEntriesByDay(entries);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('schedule_page_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(scheduleControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        icon: const Icon(Icons.add),
        label: Text(l10n.tr('schedule_add_block')),
        onPressed: () async {
          await _showEntryEditor(context, l10n);
        },
      ),
      body: scheduleState.isLoading && entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(scheduleControllerProvider.notifier).refresh(),
              child: grouped.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            l10n.tr('schedule_empty_state'),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      itemCount: grouped.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final group = grouped[index];
                        return _ScheduleDaySection(
                          date: group.date,
                          entries: group.entries,
                          onEdit: (entry) =>
                              _showEntryEditor(context, l10n, existing: entry),
                          onDelete: (entry) => ref
                              .read(scheduleControllerProvider.notifier)
                              .deleteEntry(entry.id),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _showEntryEditor(
    BuildContext context,
    AppLocalizations l10n, {
    ScheduleEntry? existing,
  }) async {
    final notifier = ref.read(scheduleControllerProvider.notifier);
    final routines = ref.read(scheduleControllerProvider).routines;
    final now = DateTime.now();
    final initialStart = existing?.startTime ?? now;
    final initialEnd = existing?.endTime ?? now.add(const Duration(hours: 1));
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var startTime = initialStart;
    var endTime = initialEnd;
    var repeatRule = existing?.repeatRule ?? ScheduleRepeatRule.none;
    var routineType = existing?.routineType ?? ScheduleRoutineType.builtIn;
    // TODO(schedule-data): Replace fallback routine metadata with repository-backed defaults.
    // 현재 기본 루틴 ID와 라벨이 코드 상수로 고정되어 사용자 설정/DB 값과 동기화되지 않습니다.
    var routineId =
        existing?.routineId ?? routines.firstOrNull?.id ?? 'focus_default';
    var routineLabel = existing?.title ?? l10n.tr('schedule_default_focus');
    if (existing != null) {
      routineLabel = existing.title;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              Future<void> pickStart() async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(startTime),
                );
                if (picked != null) {
                  setState(() {
                    startTime = DateTime(
                      startTime.year,
                      startTime.month,
                      startTime.day,
                      picked.hour,
                      picked.minute,
                    );
                    if (!startTime.isBefore(endTime)) {
                      endTime = startTime.add(const Duration(minutes: 30));
                    }
                  });
                }
              }

              Future<void> pickEnd() async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(endTime),
                );
                if (picked != null) {
                  setState(() {
                    endTime = DateTime(
                      endTime.year,
                      endTime.month,
                      endTime.day,
                      picked.hour,
                      picked.minute,
                    );
                    if (!endTime.isAfter(startTime)) {
                      endTime = startTime.add(const Duration(minutes: 30));
                    }
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null
                          ? l10n.tr('schedule_add_block')
                          : l10n.tr('schedule_edit_block'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.tr('schedule_field_title'),
                        hintText: 'e.g. Morning Focus Session',
                        errorText: titleController.text.trim().isEmpty && titleController.text.isNotEmpty
                            ? 'Title cannot be empty'
                            : null,
                      ),
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: l10n.tr('schedule_field_start'),
                            value: startTime,
                            onTap: pickStart,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeField(
                            label: l10n.tr('schedule_field_end'),
                            value: endTime,
                            onTap: pickEnd,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<ScheduleRepeatRule>(
                      initialSelection: repeatRule,
                      label: Text(l10n.tr('schedule_field_repeat')),
                      dropdownMenuEntries: [
                        for (final rule in ScheduleRepeatRule.values)
                          DropdownMenuEntry(
                            value: rule,
                            label: l10n.tr('schedule_repeat_${rule.name}'),
                          ),
                      ],
                      onSelected: (value) {
                        if (value != null) {
                          setState(() => repeatRule = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<ScheduleRoutineType>(
                      initialSelection: routineType,
                      label: Text(l10n.tr('schedule_field_routine_type')),
                      dropdownMenuEntries: [
                        for (final type in ScheduleRoutineType.values)
                          DropdownMenuEntry(
                            value: type,
                            label: l10n.tr(
                              'schedule_routine_type_${type.name}',
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value != null) {
                          setState(() => routineType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (routineType == ScheduleRoutineType.custom)
                      DropdownMenu<String>(
                        initialSelection: routines.isEmpty
                            ? null
                            : routines
                                  .firstWhere(
                                    (routine) => routine.id == routineId,
                                    orElse: () => routines.first,
                                  )
                                  .id,
                        label: Text(l10n.tr('schedule_field_select_custom')),
                        dropdownMenuEntries: [
                          for (final routine in routines)
                            DropdownMenuEntry(
                              value: routine.id,
                              label: routine.title,
                            ),
                        ],
                        onSelected: (value) {
                          if (value != null) {
                            setState(() {
                              routineId = value;
                              routineLabel = routines
                                  .firstWhere((routine) => routine.id == value)
                                  .title;
                            });
                          }
                        },
                      )
                    else
                      TextField(
                        controller: TextEditingController(text: routineLabel),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.tr('schedule_field_built_in_label'),
                          helperText: l10n.tr('schedule_field_built_in_helper'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: l10n.tr('schedule_field_notes'),
                        hintText: 'Optional notes about this schedule block',
                        helperText: 'Add any relevant details or reminders',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.tr('common_cancel')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Title is required'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            await notifier.addOrUpdateEntry(
                              ScheduleEntry(
                                id: existing?.id ?? _uuid.v4(),
                                startTime: startTime,
                                endTime: endTime,
                                title: title,
                                routineId: routineId,
                                routineType: routineType,
                                repeatRule: repeatRule,
                                notes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
                                createdAt:
                                    existing?.createdAt ??
                                    DateTime.now().toUtc(),
                                updatedAt: DateTime.now().toUtc(),
                              ),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                          },
                          child: Text(
                            existing == null
                                ? l10n.tr('common_add')
                                : l10n.tr('common_save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<_ScheduleEntryGroup> _groupEntriesByDay(List<ScheduleEntry> entries) {
    final Map<DateTime, List<ScheduleEntry>> grouped = {};
    for (final entry in entries) {
      final dateKey = DateTime(
        entry.startTime.year,
        entry.startTime.month,
        entry.startTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    final groups =
        grouped.entries
            .map(
              (entry) => _ScheduleEntryGroup(
                date: entry.key,
                entries: entry.value
                  ..sort((a, b) => a.startTime.compareTo(b.startTime)),
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return groups;
  }
}

class _ScheduleEntryGroup {
  const _ScheduleEntryGroup({required this.date, required this.entries});

  final DateTime date;
  final List<ScheduleEntry> entries;
}

class _ScheduleDaySection extends StatelessWidget {
  const _ScheduleDaySection({
    required this.date,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final List<ScheduleEntry> entries;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<ScheduleEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMMEEEEd().format(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) {
          final timeLabel =
              '${DateFormat.Hm().format(entry.startTime)} – '
              '${DateFormat.Hm().format(entry.endTime)}';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(entry.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeLabel),
                  Text(l10n.tr('schedule_repeat_${entry.repeatRule.name}')),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Text(entry.notes!),
                ],
              ),
              onTap: () => onEdit(entry),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(entry),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              DateFormat.Hm().format(value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
