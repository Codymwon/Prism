package com.prism.prism

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
        val streak = prefs.getLong("flutter.journal_streak", 0L).toInt()
        val todayReflected = prefs.getBoolean("flutter.today_reflected", false)
        
        // Theme Colors configuration
        val themeType = prefs.getLong("flutter.themeType", 0L).toInt()
        val isSystemDark = (context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES

        val bgHex: String
        val accentHex: String
        val textPrimaryHex: String
        val textSecondaryHex: String

        if (themeType == 0) {
            if (isSystemDark) {
                bgHex = "#1C1C1E"
                accentHex = "#E07A5F"
                textPrimaryHex = "#F2F2F7"
                textSecondaryHex = "#8E8E93"
            } else {
                bgHex = "#FAF8F4"
                accentHex = "#C8A97E"
                textPrimaryHex = "#2D2A26"
                textSecondaryHex = "#7A746B"
            }
        } else {
            bgHex = prefs.getString("flutter.theme_widget_bg", "#18181C") ?: "#18181C"
            accentHex = prefs.getString("flutter.theme_widget_accent", "#7C6FF7") ?: "#7C6FF7"
            textPrimaryHex = prefs.getString("flutter.theme_widget_text_primary", "#FFFFFF") ?: "#FFFFFF"
            textSecondaryHex = prefs.getString("flutter.theme_widget_text_secondary", "#88FFFFFF") ?: "#88FFFFFF"
        }

        for (appWidgetId in appWidgetIds) {
            val remoteViews = RemoteViews(context.packageName, R.layout.streak_widget)

            // 1. Set reflection status icon first (so color filters apply correctly to the set image resource)
            remoteViews.setImageViewResource(
                R.id.reflection_status_icon,
                if (todayReflected) R.drawable.ic_calendar_check else R.drawable.ic_calendar_pending
            )

            // 2. Dynamic Coloring
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
                val fallbackBg = Color.parseColor("#1C1C1E")
                val fallbackAccent = Color.parseColor("#E07A5F")
                val fallbackTextPrimary = Color.parseColor("#F2F2F7")
                val fallbackTextSecondary = Color.parseColor("#8E8E93")

                remoteViews.setInt(R.id.widget_background, "setColorFilter", fallbackBg)
                remoteViews.setInt(R.id.streak_fire_icon, "setColorFilter", fallbackAccent)
                remoteViews.setInt(R.id.reflection_status_icon, "setColorFilter", if (todayReflected) fallbackAccent else fallbackTextSecondary)
                
                remoteViews.setTextColor(R.id.streak_count_text, fallbackTextPrimary)
                remoteViews.setTextColor(R.id.streak_label, fallbackTextSecondary)
            }

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
