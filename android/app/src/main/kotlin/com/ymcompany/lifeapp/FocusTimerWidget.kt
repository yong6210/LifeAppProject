package com.ymcompany.lifeapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import java.util.concurrent.TimeUnit

data class FocusWidgetState(
    val mode: String,
    val segmentTitle: String,
    val remainingSeconds: Int,
    val totalSeconds: Int,
    val isPaused: Boolean,
    val upNext: String?,
) {
    val progress: Int
        get() = if (totalSeconds <= 0) 0 else {
            val completed = totalSeconds - remainingSeconds.coerceAtLeast(0)
            ((completed.toDouble() / totalSeconds.toDouble()) * 100).toInt().coerceIn(0, 100)
        }
}

class FocusTimerWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        val defaultState = FocusWidgetState(
            mode = "focus",
            segmentTitle = context.getString(R.string.widget_focus_default_title),
            remainingSeconds = 0,
            totalSeconds = 0,
            isPaused = false,
            upNext = null,
        )
        appWidgetIds.forEach { id ->
            val views = buildRemoteViews(context, defaultState)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        private const val OPEN_APP_REQUEST_CODE = 6401

        fun updateAll(context: Context, state: FocusWidgetState) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, FocusTimerWidget::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) {
                return
            }
            val views = buildRemoteViews(context, state)
            ids.forEach { id -> manager.updateAppWidget(id, views) }
        }

        fun clear(context: Context) {
            val defaultState = FocusWidgetState(
                mode = "focus",
                segmentTitle = context.getString(R.string.widget_focus_default_title),
                remainingSeconds = 0,
                totalSeconds = 0,
                isPaused = false,
                upNext = null,
            )
            updateAll(context, defaultState)
        }

        private fun buildRemoteViews(
            context: Context,
            state: FocusWidgetState,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_focus_timer)
            views.setTextViewText(R.id.widgetTitle, titleForState(context, state))
            views.setTextViewText(R.id.widgetSubtitle, subtitleForState(context, state))
            views.setTextViewText(R.id.widgetCountdown, formatRemaining(state.remainingSeconds))
            views.setProgressBar(R.id.widgetProgress, 100, state.progress, false)
            val intent = Intent(context, MainActivity::class.java)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or pendingImmutableFlag()
            val pendingIntent = PendingIntent.getActivity(
                context,
                OPEN_APP_REQUEST_CODE,
                intent,
                flags,
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            return views
        }

        private fun titleForState(context: Context, state: FocusWidgetState): String {
            return when {
                state.isPaused -> context.getString(
                    R.string.widget_focus_paused_title,
                    state.segmentTitle,
                )
                state.remainingSeconds <= 0 -> context.getString(
                    R.string.widget_focus_ready_title,
                )
                else -> context.getString(
                    R.string.widget_focus_running_title,
                    state.segmentTitle,
                )
            }
        }

        private fun subtitleForState(context: Context, state: FocusWidgetState): String {
            return when {
                state.remainingSeconds <= 0 -> context.getString(R.string.widget_focus_subtitle_idle)
                state.isPaused -> context.getString(R.string.widget_focus_subtitle_paused)
                !state.upNext.isNullOrEmpty() -> context.getString(
                    R.string.widget_focus_subtitle_up_next,
                    state.upNext,
                )
                else -> context.getString(R.string.widget_focus_subtitle_running)
            }
        }

        private fun formatRemaining(seconds: Int): String {
            val clamped = seconds.coerceAtLeast(0)
            val hours = TimeUnit.SECONDS.toHours(clamped.toLong())
            val minutes = TimeUnit.SECONDS.toMinutes(clamped.toLong()) % 60
            val secs = clamped % 60
            return if (hours > 0) {
                String.format("%d:%02d:%02d", hours, minutes, secs)
            } else {
                String.format("%02d:%02d", minutes, secs)
            }
        }

        private fun pendingImmutableFlag(): Int =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
    }
}
