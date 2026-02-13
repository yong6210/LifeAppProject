import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:life_app/design/ui_tokens.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/schedule_providers.dart';
import 'package:life_app/services/schedule/schedule_models.dart';
import 'package:life_app/widgets/app_state_widgets.dart';

enum _ScheduleFilter { all, tasks, routine, done }

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final _uuid = const Uuid();
  _ScheduleFilter _filter = _ScheduleFilter.all;

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleControllerProvider);
    final l10n = context.l10n;
    final entries = [...scheduleState.entries]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final filteredEntries = _applyFilter(entries);
    final taskEntries = filteredEntries.where(_isTaskEntry).toList();
    final routineEntries = filteredEntries.where(_isRoutineEntry).toList();
    final hasVisibleItems = taskEntries.isNotEmpty || routineEntries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('schedule_page_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
          ? Center(
              child: AppLoadingState(
                title: l10n.tr('schedule_loading_title'),
                message: l10n.tr('schedule_loading_message'),
              ),
            )
          : scheduleState.error != null && entries.isEmpty
              ? Center(
                  child: AppErrorState(
                    title: l10n.tr('schedule_error_title'),
                    message: '${scheduleState.error}',
                    retryLabel: l10n.tr('schedule_error_retry'),
                    onRetry: () =>
                        ref.read(scheduleControllerProvider.notifier).refresh(),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(scheduleControllerProvider.notifier).refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                    children: [
                      _ScheduleFilterRow(
                        selected: _filter,
                        onChanged: (value) {
                          setState(() {
                            _filter = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!hasVisibleItems)
                        AppEmptyState(
                          title: l10n.tr('schedule_empty_state'),
                          message: l10n.tr('schedule_loading_message'),
                          actionLabel: l10n.tr('schedule_empty_cta'),
                          onAction: () => _showEntryEditor(context, l10n),
                          icon: Icons.checklist_outlined,
                        )
                      else ...[
                        _ScheduleSectionHeader(
                          title: l10n.tr('schedule_section_now_title'),
                          count: taskEntries.length,
                        ),
                        const SizedBox(height: 8),
                        if (taskEntries.isEmpty)
                          _ScheduleSectionPlaceholder(
                            text: l10n.tr('schedule_section_now_empty'),
                          ),
                        for (final entry in taskEntries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ScheduleExecutionTile(
                              entry: entry,
                              onEdit: () => _showEntryEditor(context, l10n,
                                  existing: entry),
                              onDelete: () => ref
                                  .read(scheduleControllerProvider.notifier)
                                  .deleteEntry(entry.id),
                              onToggleDone: (nextValue) =>
                                  _toggleCompletion(entry, nextValue),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _ScheduleSectionHeader(
                          title: l10n.tr('schedule_section_routine_title'),
                          count: routineEntries.length,
                        ),
                        const SizedBox(height: 8),
                        if (routineEntries.isEmpty)
                          _ScheduleSectionPlaceholder(
                            text: l10n.tr('schedule_section_routine_empty'),
                          ),
                        for (final entry in routineEntries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ScheduleExecutionTile(
                              entry: entry,
                              onEdit: () => _showEntryEditor(context, l10n,
                                  existing: entry),
                              onDelete: () => ref
                                  .read(scheduleControllerProvider.notifier)
                                  .deleteEntry(entry.id),
                              onToggleDone: (nextValue) =>
                                  _toggleCompletion(entry, nextValue),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  List<ScheduleEntry> _applyFilter(List<ScheduleEntry> entries) {
    switch (_filter) {
      case _ScheduleFilter.all:
        return entries;
      case _ScheduleFilter.tasks:
        return entries.where(_isTaskEntry).toList();
      case _ScheduleFilter.routine:
        return entries.where(_isRoutineEntry).toList();
      case _ScheduleFilter.done:
        return entries.where((entry) => entry.isCompleted).toList();
    }
  }

  bool _isTaskEntry(ScheduleEntry entry) {
    return entry.repeatRule == ScheduleRepeatRule.none &&
        entry.routineType == ScheduleRoutineType.custom;
  }

  bool _isRoutineEntry(ScheduleEntry entry) => !_isTaskEntry(entry);

  Future<void> _toggleCompletion(ScheduleEntry entry, bool nextValue) async {
    await ref.read(scheduleControllerProvider.notifier).addOrUpdateEntry(
          entry.copyWith(
            isCompleted: nextValue,
            updatedAt: DateTime.now().toUtc(),
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
                        hintText: l10n.tr('schedule_field_title_hint'),
                        errorText: titleController.text.trim().isEmpty &&
                                titleController.text.isNotEmpty
                            ? l10n.tr('schedule_field_title_required')
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
                            label:
                                l10n.tr('schedule_routine_type_${type.name}'),
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
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.tr('schedule_field_built_in_label'),
                          helperText: l10n.tr('schedule_field_built_in_helper'),
                        ),
                        child: Text(routineLabel),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: l10n.tr('schedule_field_notes'),
                        hintText: l10n.tr('schedule_field_notes_hint'),
                        helperText: l10n.tr('schedule_field_notes_helper'),
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
                                SnackBar(
                                  content: Text(
                                    l10n.tr('schedule_field_title_required'),
                                  ),
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
                                isCompleted: existing?.isCompleted ?? false,
                                notes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
                                createdAt: existing?.createdAt ??
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
}

class _ScheduleFilterRow extends StatelessWidget {
  const _ScheduleFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final _ScheduleFilter selected;
  final ValueChanged<_ScheduleFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (_ScheduleFilter.all, l10n.tr('schedule_filter_all')),
      (_ScheduleFilter.tasks, l10n.tr('schedule_filter_tasks')),
      (_ScheduleFilter.routine, l10n.tr('schedule_filter_routine')),
      (_ScheduleFilter.done, l10n.tr('schedule_filter_done')),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (filter, label) in items)
          FilterChip(
            selected: selected == filter,
            label: Text(label),
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}

class _ScheduleSectionHeader extends StatelessWidget {
  const _ScheduleSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ScheduleSectionPlaceholder extends StatelessWidget {
  const _ScheduleSectionPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(UiRadii.sm),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ScheduleExecutionTile extends StatelessWidget {
  const _ScheduleExecutionTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDone,
  });

  final ScheduleEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final status = _entryStatus(entry);
    final statusText = switch (status) {
      _EntryStatus.urgent => l10n.tr('schedule_status_urgent'),
      _EntryStatus.normal => l10n.tr('schedule_status_normal'),
      _EntryStatus.done => l10n.tr('schedule_status_done'),
    };
    final statusColor = switch (status) {
      _EntryStatus.urgent => theme.colorScheme.error,
      _EntryStatus.normal => theme.colorScheme.secondary,
      _EntryStatus.done => theme.colorScheme.primary,
    };
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final start = entry.startTime.toLocal();
    final end = entry.endTime.toLocal();
    final timeLabel = '${DateFormat.Md(localeTag).format(start)} · '
        '${DateFormat.Hm(localeTag).format(start)} - '
        '${DateFormat.Hm(localeTag).format(end)}';
    final repeatIcon = entry.repeatRule == ScheduleRepeatRule.none
        ? Icons.flag_outlined
        : Icons.repeat_rounded;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(UiRadii.sm),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: entry.isCompleted,
                onChanged: (value) {
                  if (value == null) return;
                  onToggleDone(value);
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: entry.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(UiRadii.pill),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    repeatIcon,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  PopupMenuButton<_TileAction>(
                    icon: const Icon(Icons.more_horiz),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _TileAction.edit,
                        child: Text(l10n.tr('schedule_action_edit')),
                      ),
                      PopupMenuItem(
                        value: _TileAction.delete,
                        child: Text(l10n.tr('schedule_action_delete')),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case _TileAction.edit:
                          onEdit();
                          break;
                        case _TileAction.delete:
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _EntryStatus _entryStatus(ScheduleEntry entry) {
    if (entry.isCompleted) return _EntryStatus.done;
    final remaining = entry.startTime.difference(DateTime.now()).inMinutes;
    if (remaining <= 60) return _EntryStatus.urgent;
    return _EntryStatus.normal;
  }
}

enum _EntryStatus { urgent, normal, done }

enum _TileAction { edit, delete }

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
      borderRadius: BorderRadius.circular(UiRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(UiRadii.sm),
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
