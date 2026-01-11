import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:life_app/providers/session_providers.dart';

class WidgetUpdateService {
  static const _appGroupId = 'group.com.example.lifeapp.widgets'; // TODO: Replace with your App Group ID
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
        '${summary.sleep}h',
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
