package com.ymcompany.lifeapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class LifeAppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.life_app_widget).apply {
                val focus = widgetData.getString("today_focus", "--")
                val workout = widgetData.getString("today_workout", "--")
                val sleep = widgetData.getString("today_sleep", "--")

                setTextViewText(R.id.widget_focus, focus)
                setTextViewText(R.id.widget_workout, workout)
                setTextViewText(R.id.widget_sleep, sleep)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
