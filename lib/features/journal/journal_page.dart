import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:life_app/features/journal/journal_entry.dart';

/// Basic screen scaffolding for future sleep/mood journal work.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const JournalPage());
  }

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _formKey = GlobalKey<FormState>();
  final _moodController = TextEditingController();
  final _notesController = TextEditingController();
  final List<JournalEntry> _entries = [];
  double _sleepHours = 7;
  String? _energyLevel;
  DateTime _entryDate = DateTime.now();

  @override
  void dispose() {
    _moodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep & Mood Journal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DatePickerField(
              initialDate: _entryDate,
              onChanged: (value) => setState(() => _entryDate = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _moodController,
              decoration: const InputDecoration(
                labelText: 'Mood keyword',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a mood' : null,
            ),
            const SizedBox(height: 12),
            _EnergySelector(
              value: _energyLevel,
              onChanged: (value) => setState(() => _energyLevel = value),
            ),
            const SizedBox(height: 12),
            Text('Sleep hours: ${_sleepHours.toStringAsFixed(1)} h'),
            Slider(
              min: 0,
              max: 12,
              divisions: 24,
              value: _sleepHours,
              label: _sleepHours.toStringAsFixed(1),
              onChanged: (value) => setState(() => _sleepHours = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Add entry')),
            const SizedBox(height: 24),
            const Divider(),
            Text(
              'Recent entries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              const Text('Entries will appear here once you add them.'),
            for (final entry in _entries.reversed)
              _JournalEntryTile(
                entry: entry,
                onRemove: () => setState(
                  () => _entries.removeWhere((e) => e.id == entry.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _entryDate,
      mood: _moodController.text.trim(),
      sleepHours: _sleepHours,
      energyLevel: _energyLevel,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() {
      _entries.add(entry);
      _moodController.clear();
      _notesController.clear();
      _sleepHours = 7;
      _energyLevel = null;
      _entryDate = DateTime.now();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entry saved')));
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

class _JournalEntryTile extends StatelessWidget {
  const _JournalEntryTile({required this.entry, required this.onRemove});

  final JournalEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('${DateFormat.yMMMd().format(entry.date)} — ${entry.mood}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sleep: ${entry.sleepHours.toStringAsFixed(1)} h'),
            if (entry.energyLevel != null) Text('Energy: ${entry.energyLevel}'),
            if (entry.notes != null && entry.notes!.isNotEmpty)
              Text(entry.notes!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: theme.colorScheme.error,
          onPressed: onRemove,
        ),
      ),
    );
  }
}
