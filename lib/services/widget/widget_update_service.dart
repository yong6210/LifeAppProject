import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:life_app/providers/session_providers.dart';

class WidgetUpdateService {
  static const _appGroupId =
      'group.com.example.lifeapp.widgets'; // TODO: Replace with your App Group ID
  static const _iOSWidgetName = 'LifeAppWidgets';
  static const _androidWidgetName = 'LifeAppWidgetProvider';

  static Future<void> init() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return;
    }
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } on MissingPluginException {
      // Widget APIs are unavailable on some platforms.
    }
  }

  static Future<void> updateWidget(TodaySummary summary) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return;
    }
    try {
      const focusGoal = 25;
      const workoutGoal = 30;
      const sleepGoalMinutes = 8 * 60;
      final totalRate = (((summary.focus / focusGoal).clamp(0.0, 1.0) +
                  (summary.workout / workoutGoal).clamp(0.0, 1.0) +
                  (summary.sleep / sleepGoalMinutes).clamp(0.0, 1.0)) /
              3)
          .clamp(0.0, 1.0);
      final completionPercent = (totalRate * 100).round();
      final sleepHours = (summary.sleep / 60).toStringAsFixed(1);

      final nextAction = summary.focus < focusGoal
          ? 'focus'
          : (summary.workout < workoutGoal
              ? 'workout'
              : (summary.sleep < sleepGoalMinutes ? 'sleep' : 'stats'));

      await HomeWidget.saveWidgetData<String>(
        'today_focus',
        '${summary.focus}m',
      );
      await HomeWidget.saveWidgetData<String>(
        'today_workout',
        '${summary.workout}m',
      );
      await HomeWidget.saveWidgetData<String>(
        'today_sleep',
        '${sleepHours}h',
      );
      await HomeWidget.saveWidgetData<String>(
        'today_completion',
        '$completionPercent%',
      );
      await HomeWidget.saveWidgetData<String>(
        'next_action',
        nextAction,
      );

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } on MissingPluginException {
      // Widget APIs are unavailable on some platforms.
    }
  }
}
