import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/journal/journal_entry.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/journal_providers.dart';
import 'package:life_app/services/journal/life_buddy_comment_service.dart';
import 'package:life_app/widgets/app_state_widgets.dart';
import 'package:life_app/widgets/glass_card.dart';

/// Stage 0 journal page with 30-day retention and monthly recap.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const JournalPage());
  }

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  double _sleepHours = 7;
  String? _energyLevel;
  DateTime _entryDate = DateTime.now();
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedMood;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalEntriesProvider);
    final summaryAsync = ref.watch(journalSummaryProvider);
    final commentAsync = ref.watch(journalBuddyCommentProvider);
    final entries = entriesAsync.asData?.value ?? const <JournalEntry>[];
    final entryMap = <DateTime, JournalEntry>{
      for (final entry in entries) DateUtils.dateOnly(entry.date): entry,
    };
    final fallbackDate = entries.isNotEmpty
        ? DateUtils.dateOnly(entries.first.date)
        : _selectedDate;
    final effectiveDate =
        entryMap.containsKey(_selectedDate) ? _selectedDate : fallbackDate;
    final selectedEntry = entryMap[effectiveDate];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a1a20),
                    const Color(0xFF0F1419),
                    const Color(0xFF0a0a0f),
                  ]
                : [
                    const Color(0xFFF5F5FA),
                    const Color(0xFFE8F0FE),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (canPop) ...[
                      GlassCard(
                        onTap: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color:
                              isDark ? Colors.white : AppTheme.electricViolet,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.teal, AppTheme.eucalyptus],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sleep & Mood Journal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _JournalCalendar(
                        entries: entriesAsync,
                        selectedDate: effectiveDate,
                        visibleMonth: _visibleMonth,
                        onMonthChanged: _changeMonth,
                        onDateSelected: _handleDateSelected,
                        onRetry: () => ref.invalidate(journalEntriesProvider),
                      ),
                      const SizedBox(height: 16),
                      _EntryDetailCard(
                        selectedDate: effectiveDate,
                        entry: selectedEntry,
                        onWriteEntry: () => _prefillEntryForDate(effectiveDate),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _DatePickerField(
                        initialDate: _entryDate,
                        onChanged: (value) =>
                            setState(() => _entryDate = value),
                      ),
                      const SizedBox(height: 12),
                      _MoodChipSelector(
                        value: _selectedMood,
                        onChanged: (value) =>
                            setState(() => _selectedMood = value),
                      ),
                      const SizedBox(height: 12),
                      _EnergySelector(
                        value: _energyLevel,
                        onChanged: (value) =>
                            setState(() => _energyLevel = value),
                      ),
                      const SizedBox(height: 12),
                      Text('Sleep hours: ${_sleepHours.toStringAsFixed(1)} h'),
                      Slider(
                        min: 0,
                        max: 12,
                        divisions: 24,
                        value: _sleepHours,
                        label: _sleepHours.toStringAsFixed(1),
                        onChanged: (value) =>
                            setState(() => _sleepHours = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                          hintText:
                              'How was your day? Any thoughts or reflections...',
                          helperText: 'Capture your thoughts and feelings',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                          onPressed: _submit, child: const Text('Add entry')),
                      const SizedBox(height: 24),
                      _MonthlyRecapCard(
                        summary: summaryAsync,
                        onRetry: () => ref.invalidate(journalSummaryProvider),
                      ),
                      const SizedBox(height: 16),
                      _BuddyCommentCard(
                        comment: commentAsync,
                        onRetry: () =>
                            ref.invalidate(journalBuddyCommentProvider),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      Text('Timeline',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _TimelineSection(
                        entries: entriesAsync,
                        onRemove: (entry) => ref
                            .read(journalEntriesProvider.notifier)
                            .deleteEntry(entry),
                        onSelect: (entry) => _handleTimelineTap(entry, entries),
                        onRetry: () => ref.invalidate(journalEntriesProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _entryDate,
      mood: _selectedMood!,
      sleepHours: _sleepHours,
      energyLevel: _energyLevel,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(journalEntriesProvider.notifier).addEntry(entry);
    if (!mounted) return;

    setState(() {
      _notesController.clear();
      _sleepHours = 7;
      _energyLevel = null;
      _entryDate = DateTime.now();
      _selectedDate = DateUtils.dateOnly(entry.date);
      _visibleMonth = DateTime(entry.date.year, entry.date.month);
      _selectedMood = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entry saved')));
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  void _handleDateSelected(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    setState(() {
      _selectedDate = normalized;
      _visibleMonth = DateTime(normalized.year, normalized.month);
      _entryDate = DateTime(normalized.year, normalized.month, normalized.day);
    });
  }

  void _handleTimelineTap(JournalEntry entry, List<JournalEntry> allEntries) {
    _handleDateSelected(entry.date);
    const engine = LifeBuddyCommentEngine();
    final comment = engine.generate(allEntries);
    final suggestions = _suggestionsForEntry(entry);
    _showEntryDetailSheet(entry, comment, suggestions);
  }

  Future<void> _showEntryDetailSheet(
    JournalEntry entry,
    LifeBuddyComment? comment,
    List<_RoutineSuggestion> suggestions,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JournalEntryDetailSheet(
        entry: entry,
        comment: comment,
        suggestions: suggestions,
        onStartNewEntry: () {
          Navigator.of(context).pop();
          _prefillEntryForDate(entry.date);
        },
      ),
    );
  }

  List<_RoutineSuggestion> _suggestionsForEntry(JournalEntry entry) {
    final mood = entry.mood.trim();
    final energy = entry.energyLevel?.toLowerCase() ?? '';
    final notes = entry.notes?.toLowerCase() ?? '';
    final suggestions = <_RoutineSuggestion>[];

    void addSuggestion({
      required String title,
      required String description,
      required IconData icon,
    }) {
      suggestions.add(
        _RoutineSuggestion(title: title, description: description, icon: icon),
      );
    }

    if (mood == '무기력해요' || energy.contains('low')) {
      addSuggestion(
        title: '모닝 스트레칭 10분',
        description: '가벼운 전신 스트레칭으로 하루 에너지를 깨워보세요.',
        icon: Icons.self_improvement_outlined,
      );
    }

    if (mood == '피곤해요' || entry.sleepHours < 6) {
      addSuggestion(
        title: '딥 릴랙스 수면 루틴',
        description: '취침 루틴에 깊은 릴랙스 사운드를 추가해 회복을 돕습니다.',
        icon: Icons.bedtime_outlined,
      );
    }

    if (mood == '걱정돼요' || notes.contains('걱정')) {
      addSuggestion(
        title: '5분 호흡 명상',
        description: '잠들기 전 숨 고르기 루틴으로 마음을 안정시켜요.',
        icon: Icons.spa_outlined,
      );
    }

    if (notes.contains('야근') || notes.contains('overtime')) {
      addSuggestion(
        title: '퇴근 후 회복 루틴',
        description: '허리 스트레칭과 따뜻한 음료로 긴장을 풀어보세요.',
        icon: Icons.nightlight_round,
      );
    }

    if (suggestions.isEmpty) {
      addSuggestion(
        title: '오늘 하루 복기',
        description: '짧은 저널 프롬프트로 내일의 루틴을 정리해요.',
        icon: Icons.note_alt_outlined,
      );
    }

    return suggestions;
  }

  void _prefillEntryForDate(DateTime date) {
    setState(() {
      _entryDate = DateTime(date.year, date.month, date.day);
      _selectedDate = DateUtils.dateOnly(date);
    });
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.initialDate, required this.onChanged});

  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: DateFormat.yMMMMd().format(initialDate),
    );

    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Entry date',
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }
}

class _MoodChipSelector extends StatelessWidget {
  const _MoodChipSelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _options = <String>[
    '좋아요',
    '뿌듯해요',
    '설레요',
    '피곤해요',
    '무기력해요',
    '걱정돼요',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<String>(
      initialValue: value,
      validator: (selection) => selection == null ? '오늘의 감정을 선택해 주세요' : null,
      builder: (state) {
        if (state.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.mounted) {
              state.didChange(value);
            }
          });
        }
        final current = value ?? state.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 기분',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in _options)
                  ChoiceChip(
                    label: Text(option),
                    selected: current == option,
                    onSelected: (selected) {
                      final next = selected ? option : null;
                      state.didChange(next);
                      onChanged(next);
                    },
                  ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  state.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EnergySelector extends StatelessWidget {
  const _EnergySelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Energy level',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Low', child: Text('Low')),
        DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
        DropdownMenuItem(value: 'Energetic', child: Text('Energetic')),
      ],
      onChanged: onChanged,
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.entries,
    required this.onRemove,
    required this.onSelect,
    required this.onRetry,
  });

  final AsyncValue<List<JournalEntry>> entries;
  final ValueChanged<JournalEntry> onRemove;
  final ValueChanged<JournalEntry> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return entries.when(
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(
            title: '최근 기록이 없어요',
            message: '오늘 하루를 짧게 남겨볼까요?',
            actionLabel: null,
          );
        }
        return Column(
          children: [
            for (var index = 0; index < items.length; index++)
              _TimelineEntry(
                entry: items[index],
                isFirst: index == 0,
                isLast: index == items.length - 1,
                onTap: () => onSelect(items[index]),
                onRemove: () => onRemove(items[index]),
              ),
          ],
        );
      },
      error: (error, _) => AppErrorState(
        title: '저널을 불러오지 못했어요',
        message: '$error',
        retryLabel: context.l10n.tr('common_retry'),
        onRetry: onRetry,
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: AppLoadingState(title: '저널 기록 불러오는 중', compact: true),
      ),
    );
  }
}

class _JournalCalendar extends StatelessWidget {
  const _JournalCalendar({
    required this.entries,
    required this.selectedDate,
    required this.visibleMonth,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.onRetry,
  });

  final AsyncValue<List<JournalEntry>> entries;
  final DateTime selectedDate;
  final DateTime visibleMonth;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('journal-calendar-card'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: entries.when(
          loading: () => const SizedBox(
            height: 240,
            child: AppLoadingState(title: '캘린더 불러오는 중', compact: true),
          ),
          error: (error, _) => SizedBox(
            height: 240,
            child: AppErrorState(
              title: '캘린더를 불러오지 못했어요',
              message: '$error',
              retryLabel: context.l10n.tr('common_retry'),
              onRetry: onRetry,
            ),
          ),
          data: (items) {
            final entryMap = <DateTime, JournalEntry>{
              for (final entry in items) DateUtils.dateOnly(entry.date): entry,
            };
            final today = DateUtils.dateOnly(DateTime.now());
            final earliestEntry = entryMap.keys.isEmpty
                ? today
                : entryMap.keys.reduce(
                    (value, element) =>
                        element.isBefore(value) ? element : value,
                  );
            final startOfEarliest = DateTime(
              earliestEntry.year,
              earliestEntry.month,
            );
            final startOfToday = DateTime(today.year, today.month);

            final canGoPrev = _compareMonth(visibleMonth, startOfEarliest) > 0;
            final canGoNext = _compareMonth(visibleMonth, startOfToday) < 0;
            final monthLabel = DateFormat.yMMMM().format(visibleMonth);
            final days = _buildCalendarDays(visibleMonth);

            return Column(
              children: [
                Row(
                  children: [
                    Text(
                      monthLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '이전 달',
                      onPressed: canGoPrev ? () => onMonthChanged(-1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: '다음 달',
                      onPressed: canGoNext ? () => onMonthChanged(1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CalendarWeekdayLabel('일'),
                    _CalendarWeekdayLabel('월'),
                    _CalendarWeekdayLabel('화'),
                    _CalendarWeekdayLabel('수'),
                    _CalendarWeekdayLabel('목'),
                    _CalendarWeekdayLabel('금'),
                    _CalendarWeekdayLabel('토'),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final normalized = DateUtils.dateOnly(day);
                    final entry = entryMap[normalized];
                    final isCurrentMonth = day.month == visibleMonth.month;
                    final isSelected = DateUtils.isSameDay(
                      normalized,
                      selectedDate,
                    );
                    final isToday = DateUtils.isSameDay(normalized, today);
                    final isFuture = normalized.isAfter(today);
                    final cellKey = DateFormat('yyyy-MM-dd').format(normalized);

                    final backgroundColor = isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent;
                    final borderColor = isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent;
                    final baseTextColor = isCurrentMonth
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4);
                    final textColor = isFuture
                        ? baseTextColor.withValues(alpha: 0.35)
                        : baseTextColor;

                    Color? dotColor;
                    String? dotEmoji;
                    if (entry != null) {
                      dotColor = _colorForMood(entry.mood, theme);
                      dotEmoji = _emojiForMood(entry.mood);
                    }

                    return Tooltip(
                      message: entry?.mood ?? '기록 없음',
                      triggerMode: entry != null
                          ? TooltipTriggerMode.longPress
                          : TooltipTriggerMode.tap,
                      child: InkWell(
                        key: ValueKey('journal-calendar-day-$cellKey'),
                        onTap: isFuture ? null : () => onDateSelected(day),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (entry != null)
                                _MoodDot(color: dotColor!, emoji: dotEmoji)
                              else if (isToday)
                                _MoodDot(
                                  color: theme.colorScheme.primary,
                                  emoji: '•',
                                  opacity: 0.3,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<DateTime> _buildCalendarDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final weekdayFromSunday = firstOfMonth.weekday % 7;
    final start = firstOfMonth.subtract(Duration(days: weekdayFromSunday));
    return List<DateTime>.generate(
      42,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  static int _compareMonth(DateTime a, DateTime b) {
    if (a.year == b.year && a.month == b.month) return 0;
    if (a.year > b.year || (a.year == b.year && a.month > b.month)) {
      return 1;
    }
    return -1;
  }
}

class _CalendarWeekdayLabel extends StatelessWidget {
  const _CalendarWeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.color, this.emoji, this.opacity = 1});

  final Color color;
  final String? emoji;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 13))
          : null,
    );
  }
}

class _EntryDetailCard extends StatelessWidget {
  const _EntryDetailCard({
    required this.selectedDate,
    required this.entry,
    required this.onWriteEntry,
  });

  final DateTime selectedDate;
  final JournalEntry? entry;
  final VoidCallback onWriteEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMMd().format(selectedDate);
    if (entry == null) {
      return Card(
        key: const Key('journal-detail-card-empty'),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이 날짜에는 기록이 없어요. 간단하게 하루를 남겨볼까요?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onWriteEntry,
                child: const Text('이 날짜에 기록하기'),
              ),
            ],
          ),
        ),
      );
    }

    final journalEntry = entry!;
    final moodColor = _colorForMood(journalEntry.mood, theme);
    final moodEmoji = _emojiForMood(journalEntry.mood);
    return Card(
      key: const Key('journal-detail-card'),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(journalEntry.mood),
                  avatar: Text(moodEmoji),
                  backgroundColor: moodColor.withValues(alpha: 0.12),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: moodColor.darken(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '수면 ${journalEntry.sleepHours.toStringAsFixed(1)}시간'
              '${journalEntry.energyLevel != null ? ' · 에너지 ${journalEntry.energyLevel}' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (journalEntry.notes != null &&
                journalEntry.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                journalEntry.notes!,
                key: const Key('journal-entry-note'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onWriteEntry,
              child: const Text('이 날짜로 새 기록 작성'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryDetailSheet extends StatelessWidget {
  const _JournalEntryDetailSheet({
    required this.entry,
    required this.comment,
    required this.suggestions,
    required this.onStartNewEntry,
  });

  final JournalEntry entry;
  final LifeBuddyComment? comment;
  final List<_RoutineSuggestion> suggestions;
  final VoidCallback onStartNewEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMMd().format(entry.date);
    final sleepLabel = '${entry.sleepHours.toStringAsFixed(1)} h';
    final energyLabel =
        entry.energyLevel?.isNotEmpty == true ? entry.energyLevel! : null;
    final notes = entry.notes?.trim();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        key: const Key('journal-entry-detail-sheet'),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateLabel,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(entry.mood),
                                avatar: Text(_emojiForMood(entry.mood)),
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                labelStyle:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '닫기',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _JournalStatChip(
                          icon: Icons.nightlight_round,
                          label: '수면',
                          value: sleepLabel,
                        ),
                        if (energyLabel != null)
                          _JournalStatChip(
                            icon: Icons.bolt_outlined,
                            label: '에너지',
                            value: energyLabel,
                          ),
                      ],
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(notes, style: theme.textTheme.bodyLarge),
                    ],
                    if (comment != null) ...[
                      const SizedBox(height: 24),
                      Card(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Life Buddy 코멘트',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comment!.message,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '추천 루틴',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final suggestion in suggestions)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(suggestion.icon),
                                title: Text(suggestion.title),
                                subtitle: Text(suggestion.description),
                                visualDensity: VisualDensity.compact,
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '프리미엄 리포트 미리보기',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '감정·수면 그래프와 AI 코칭이 한 화면에 정리됩니다. Stage 1에서 공개될 예정이에요.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onStartNewEntry,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('이 날짜로 새 기록 작성'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalStatChip extends StatelessWidget {
  const _JournalStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label · $value', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RoutineSuggestion {
  const _RoutineSuggestion({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onRemove,
  });

  final JournalEntry entry;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodColor = _colorForMood(entry.mood, theme);
    final dateLabel = DateFormat.yMMMMd().format(entry.date);

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 4, bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moodColor.withValues(alpha: 0.35),
                  border: Border.all(color: moodColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _emojiForMood(entry.mood),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 86,
                  margin: const EdgeInsets.only(top: 4),
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Card(
                key: ValueKey('timeline-entry-${entry.id}'),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: '기록 삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: onRemove,
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(entry.mood),
                            avatar: Text(_emojiForMood(entry.mood)),
                            backgroundColor: moodColor.withValues(alpha: 0.12),
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: moodColor.darken(),
                            ),
                          ),
                          if (entry.energyLevel != null)
                            Chip(
                              label: Text('에너지 ${entry.energyLevel}'),
                              backgroundColor: theme
                                  .colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '수면 ${entry.sleepHours.toStringAsFixed(1)}시간',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            entry.notes!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorForMood(String mood, ThemeData theme) {
  switch (mood) {
    case '좋아요':
      return theme.colorScheme.secondary;
    case '뿌듯해요':
      return const Color(0xFF6C63FF);
    case '설레요':
      return const Color(0xFF00BFA6);
    case '피곤해요':
      return const Color(0xFFF57C00);
    case '무기력해요':
      return const Color(0xFFEF5350);
    case '걱정돼요':
      return const Color(0xFF8E24AA);
    default:
      return theme.colorScheme.primary;
  }
}

String _emojiForMood(String mood) {
  switch (mood) {
    case '좋아요':
      return '😊';
    case '뿌듯해요':
      return '😌';
    case '설레요':
      return '✨';
    case '피곤해요':
      return '😴';
    case '무기력해요':
      return '🥱';
    case '걱정돼요':
      return '😟';
    default:
      return '🙂';
  }
}

extension _MoodColorShade on Color {
  Color darken([double amount = 0.18]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class _MonthlyRecapCard extends StatelessWidget {
  const _MonthlyRecapCard({required this.summary, required this.onRetry});

  final AsyncValue<JournalSummary?> summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return summary.when(
      data: (value) {
        if (value == null) {
          return const AppEmptyState(
            title: '월간 리캡 준비 중',
            message: '최근 30일 기록이 쌓이면 자동으로 생성됩니다.',
            actionLabel: null,
          );
        }
        final buffer = StringBuffer();
        final averageSleep = value.averageSleepHours.toStringAsFixed(1);
        final streakLine = value.streakDays > 1
            ? '${value.streakDays}일 연속으로 저널을 남겼어요!'
            : '오늘 기록을 남기면 새로운 연속 기록이 시작돼요.';
        final moodLine = value.commonMood != null
            ? '이번 달에는 "${value.commonMood}" 느낌을 가장 자주 남겼네요.'
            : '감정 키워드를 기록하면 다음 리캡에서 더 많이 도와줄 수 있어요.';
        final energyLine = value.dominantEnergy != null
            ? '에너지 레벨은 ${value.dominantEnergy} 상태가 가장 많았어요.'
            : '에너지 레벨도 선택해 두면 맞춤 제안을 준비할 수 있어요.';
        final lastEntryDate = DateFormat.yMMMMd().format(
          value.latestEntry.date,
        );
        buffer
          ..writeln('지난 30일 동안 평균 수면은 $averageSleep시간이었어요.')
          ..writeln(
            '이번 주에는 ${value.entriesThisWeek}일 기록했고, 마지막 기록은 $lastEntryDate 기준이에요.',
          )
          ..writeln(streakLine)
          ..writeln(moodLine)
          ..writeln(energyLine);

        return Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '월간 리캡',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  buffer.toString().trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '무료 플랜은 최근 30일 데이터를 기준으로 요약해요. 더 상세한 그래프는 곧 만나볼 수 있어요!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, _) => AppErrorState(
        title: '월간 리캡을 불러오지 못했어요',
        message: '$error',
        retryLabel: context.l10n.tr('common_retry'),
        onRetry: onRetry,
      ),
      loading: () => const AppLoadingState(title: '월간 리캡 분석 중', compact: true),
    );
  }
}

class _BuddyCommentCard extends StatelessWidget {
  const _BuddyCommentCard({required this.comment, required this.onRetry});

  final AsyncValue<LifeBuddyComment?> comment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return comment.when(
      data: (value) {
        if (value == null) {
          return const SizedBox.shrink();
        }
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BuddyAvatar(emoji: '✨'),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, _) => AppErrorState(
        title: '라이프 버디 코멘트를 불러오지 못했어요',
        message: '$error',
        retryLabel: context.l10n.tr('common_retry'),
        onRetry: onRetry,
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: AppLoadingState(title: '라이프 버디 코멘트 준비 중', compact: true),
      ),
    );
  }
}

class _BuddyAvatar extends StatelessWidget {
  const _BuddyAvatar({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.55),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}
