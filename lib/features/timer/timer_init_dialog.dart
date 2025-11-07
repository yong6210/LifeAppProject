import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/settings_providers.dart';

class TimerInitDialog extends ConsumerStatefulWidget {
  const TimerInitDialog({super.key});

  @override
  ConsumerState<TimerInitDialog> createState() => _TimerInitDialogState();
}

class _TimerInitDialogState extends ConsumerState<TimerInitDialog> {
  late int focus;
  late int rest;
  late int workout;
  late int sleep;
  late bool autoBackup;

  @override
  void initState() {
    super.initState();
    final asyncSettings = ref.read(settingsFutureProvider);
    final settings = asyncSettings.maybeWhen(
      data: (value) => value,
      orElse: () => Settings(),
    );
    focus = settings.focusMinutes;
    rest = settings.restMinutes;
    workout = settings.workoutMinutes;
    sleep = settings.sleepMinutes;
    autoBackup = settings.notificationPrefs.sleepAlarm;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.tr('timer_init_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NumberField(
              label: l10n.tr('timer_init_focus_label'),
              initialValue: focus,
              onChanged: (value) => focus = value,
            ),
            _NumberField(
              label: l10n.tr('timer_init_rest_label'),
              initialValue: rest,
              onChanged: (value) => rest = value,
            ),
            _NumberField(
              label: l10n.tr('timer_init_workout_label'),
              initialValue: workout,
              onChanged: (value) => workout = value,
            ),
            _NumberField(
              label: l10n.tr('timer_init_sleep_label'),
              initialValue: sleep,
              onChanged: (value) => sleep = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.tr('common_cancel')),
        ),
        ElevatedButton(
          onPressed: () async {
            final input = {
              'focus': focus,
              'rest': rest,
              'workout': workout,
              'sleep': sleep,
            };
            try {
              await ref.read(savePresetProvider(input).future);
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.tr('timer_init_save_error', {
                        'error': error.toString(),
                      }),
                    ),
                  ),
                );
              }
            }
          },
          child: Text(l10n.tr('common_save')),
        ),
      ],
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (value) {
          final number = int.tryParse(value) ?? widget.initialValue;
          widget.onChanged(number);
        },
      ),
    );
  }
}
