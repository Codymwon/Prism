package com.meridian.meridian

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class StreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val streak = prefs.getInt("flutter.journal_streak", 0)
        val todayReflected = prefs.getBoolean("flutter.today_reflected", false)
        
        // Theme Colors (default to dark themes)
        val bgHex = prefs.getString("flutter.theme_widget_bg", "#18181C")
        val accentHex = prefs.getString("flutter.theme_widget_accent", "#7C6FF7")
        val textPrimaryHex = prefs.getString("flutter.theme_widget_text_primary", "#FFFFFF")
        val textSecondaryHex = prefs.getString("flutter.theme_widget_text_secondary", "#88FFFFFF")

        for (appWidgetId in appWidgetIds) {
            val remoteViews = RemoteViews(context.packageName, R.layout.streak_widget)

            // 1. Dynamic Coloring
            try {
                val bgCol = Color.parseColor(bgHex)
                val accentCol = Color.parseColor(accentHex)
                val textPrimaryCol = Color.parseColor(textPrimaryHex)
                val textSecondaryCol = Color.parseColor(textSecondaryHex)

                remoteViews.setInt(R.id.widget_background, "setColorFilter", bgCol)
                remoteViews.setInt(R.id.streak_fire_icon, "setColorFilter", accentCol)
                remoteViews.setInt(R.id.reflection_status_icon, "setColorFilter", if (todayReflected) accentCol else textSecondaryCol)
                
                remoteViews.setTextColor(R.id.streak_count_text, textPrimaryCol)
                remoteViews.setTextColor(R.id.streak_label, textSecondaryCol)
            } catch (e: Exception) {
                // Fallbacks in case color parsing fails
                remoteViews.setInt(R.id.widget_background, "setColorFilter", Color.parseColor("#18181C"))
                remoteViews.setInt(R.id.streak_fire_icon, "setColorFilter", Color.parseColor("#7C6FF7"))
                remoteViews.setInt(R.id.reflection_status_icon, "setColorFilter", Color.parseColor("#88FFFFFF"))
            }

            // 2. Set reflection status icon
            remoteViews.setImageViewResource(
                R.id.reflection_status_icon,
                if (todayReflected) R.drawable.ic_calendar_check else R.drawable.ic_calendar_pending
            )

            // 3. Set streak count
            remoteViews.setTextViewText(R.id.streak_count_text, "${streak}d")

            // 4. Click Intent action (opens app and handles daily note creation/editing)
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_action", "create_daily")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, remoteViews)
        }
    }
}
