import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

class TimerPermissionStatus {
  const TimerPermissionStatus({
    required this.notificationGranted,
    required this.exactAlarmGranted,
    required this.dndAccessGranted,
    required this.microphoneGranted,
  });

  final bool notificationGranted;
  final bool exactAlarmGranted;
  final bool dndAccessGranted;
  final bool microphoneGranted;

  bool get fullyGranted =>
      notificationGranted && exactAlarmGranted && dndAccessGranted;

  bool get sleepSoundReady => microphoneGranted;
}

class TimerPermissionService {
  TimerPermissionService._();

  static const _channel = MethodChannel('dev.life_app/permissions');
  static const _focusDndPromptKey = 'focus_dnd_prompt_ack';

  static Future<TimerPermissionStatus> queryStatus() async {
    var notificationGranted = true;
    var exactAlarmGranted = true;
    var dndGranted = true;
    var microphoneGranted = true;

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.status;
      notificationGranted = status.isGranted || status.isLimited;
      final micStatus = await Permission.microphone.status;
      microphoneGranted = micStatus.isGranted || micStatus.isLimited;
    }

    if (Platform.isAndroid) {
      try {
        exactAlarmGranted =
            await _channel.invokeMethod<bool>('hasExactAlarmPermission') ??
            true;
        dndGranted =
            await _channel.invokeMethod<bool>('hasNotificationPolicyAccess') ??
            true;
      } on PlatformException {
        exactAlarmGranted = true;
        dndGranted = true;
      }
    }

    return TimerPermissionStatus(
      notificationGranted: notificationGranted,
      exactAlarmGranted: exactAlarmGranted,
      dndAccessGranted: dndGranted,
      microphoneGranted: microphoneGranted,
    );
  }

  static Future<bool> ensureTimerPermissions(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    var status = await queryStatus();

    if (Platform.isAndroid || Platform.isIOS) {
      if (!status.notificationGranted) {
        AnalyticsService.logEvent('reminder_permission_prompt', {
          'type': 'notification',
          'state_before': status.notificationGranted ? 'granted' : 'denied',
        });
        final request = await Permission.notification.request();
        if (!context.mounted) {
          return false;
        }
        if (!request.isGranted && !request.isLimited) {
          _showSnack(messenger, l10n.tr('permission_notification_required'));
          return false;
        }
        status = await queryStatus();
      }
    }

    if (Platform.isAndroid) {
      if (!status.exactAlarmGranted) {
        AnalyticsService.logEvent('reminder_permission_prompt', {
          'type': 'exact_alarm',
          'state_before': status.exactAlarmGranted ? 'granted' : 'denied',
        });
        if (!context.mounted) {
          return false;
        }
        final open = await _showDialog(
          context,
          title: l10n.tr('permission_exact_title'),
          message: l10n.tr('permission_exact_message'),
        );
        if (open == true) {
          await openExactAlarmSettings();
        }
      }

      if (!status.dndAccessGranted) {
        AnalyticsService.logEvent('reminder_permission_prompt', {
          'type': 'dnd_access',
          'state_before': status.dndAccessGranted ? 'granted' : 'denied',
        });
        if (!context.mounted) {
          return false;
        }
        final open = await _showDialog(
          context,
          title: l10n.tr('permission_dnd_title'),
          message: l10n.tr('permission_dnd_message'),
        );
        if (open == true) {
          await openNotificationPolicySettings();
        }
      }
    }

    final refreshed = await queryStatus();
    return refreshed.notificationGranted && refreshed.exactAlarmGranted;
  }

  static Future<void> requestNotificationPermission(
    BuildContext context,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final status = await Permission.notification.request();
    if (!status.isGranted && !status.isLimited) {
      _showSnack(messenger, l10n.tr('permission_notification_denied'));
    }
  }

  /// Requests microphone permission with context-aware prompts for the
  /// sleep sound analysis proof-of-concept.
  static Future<bool> ensureMicrophonePermission(BuildContext context) {
    return ensureSleepSoundPermissions(context);
  }

  static Future<bool> ensureSleepSoundPermissions(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final status = await Permission.microphone.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final localL10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(localL10n.tr('timer_permission_microphone_title')),
          content: Text(localL10n.tr('timer_permission_microphone_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(localL10n.tr('common_later')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(localL10n.tr('timer_permission_microphone_action')),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) {
      return false;
    }
    final requested = await Permission.microphone.request();
    if (requested.isGranted || requested.isLimited) {
      _showSnack(messenger, l10n.tr('timer_permission_microphone_success'));
      return true;
    }

    if (requested.isPermanentlyDenied || requested.isRestricted) {
      if (!context.mounted) {
        return false;
      }
      final open = await _showDialog(
        context,
        title: l10n.tr('timer_permission_microphone_title'),
        message: l10n.tr('timer_permission_microphone_settings'),
        confirmOnly: false,
      );
      if (open == true) {
        await openAppSettings();
      }

    } else {
      _showSnack(messenger, l10n.tr('timer_permission_microphone_denied'));
    }
    return false;
  }

  static Future<void> openExactAlarmSettings() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('openExactAlarmSettings');
    } else {
      await openAppSettings();
    }
  }

  static Future<void> openNotificationPolicySettings() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('openNotificationPolicySettings');
    } else {
      await openAppSettings();
    }
  }

  /// Indicates whether we should surface the focus-mode DND educational prompt.
  static Future<bool> shouldShowFocusDndPrompt() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_focusDndPromptKey) == true) {
      return false;
    }
    final status = await queryStatus();
    return !status.dndAccessGranted;
  }

  /// Records that the user saw (and acted on) the focus-mode DND prompt.
  static Future<void> markFocusDndPromptAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusDndPromptKey, true);
  }

  static Future<bool?> _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool confirmOnly = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (!confirmOnly)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.tr('common_later')),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.tr('common_open_settings')),
            ),
          ],
        );
      },
    );
  }

  static void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

final timerPermissionStatusProvider = FutureProvider<TimerPermissionStatus>((
  ref,
) {
  return TimerPermissionService.queryStatus();
});
