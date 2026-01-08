import 'package:home_widget/home_widget.dart';
import 'package:life_app/providers/session_providers.dart';

class WidgetUpdateService {
  static const _appGroupId = 'group.com.example.lifeapp.widgets'; // TODO: Replace with your App Group ID
  static const _iOSWidgetName = 'LifeAppWidgets';
  static const _androidWidgetName = 'LifeAppWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget(TodaySummary summary) async {
    await HomeWidget.saveWidgetData<String>('today_focus', '${summary.focus}m');
    await HomeWidget.saveWidgetData<String>('today_workout', '${summary.workout}m');
    await HomeWidget.saveWidgetData<String>('today_sleep', '${summary.sleep}h');
    
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
