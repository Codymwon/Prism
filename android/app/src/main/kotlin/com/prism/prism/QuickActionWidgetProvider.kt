package com.prism.prism

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class QuickActionWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Theme Colors configuration
        val themeType = prefs.getLong("flutter.themeType", 0L).toInt()
        val isSystemDark = (context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES

        val bgHex: String
        val accentHex: String
        val textPrimaryHex: String

        if (themeType == 0) {
            if (isSystemDark) {
                bgHex = "#1C1C1E"
                accentHex = "#E07A5F"
                textPrimaryHex = "#F2F2F7"
            } else {
                bgHex = "#FAF8F4"
                accentHex = "#C8A97E"
                textPrimaryHex = "#2D2A26"
            }
        } else {
            bgHex = prefs.getString("flutter.theme_widget_bg", "#18181C") ?: "#18181C"
            accentHex = prefs.getString("flutter.theme_widget_accent", "#7C6FF7") ?: "#7C6FF7"
            textPrimaryHex = prefs.getString("flutter.theme_widget_text_primary", "#FFFFFF") ?: "#FFFFFF"
        }

        for (appWidgetId in appWidgetIds) {
            val remoteViews = RemoteViews(context.packageName, R.layout.quick_action_widget)

            // 1. Dynamic Colors
            try {
                val bgCol = Color.parseColor(bgHex)
                val accentCol = Color.parseColor(accentHex)
                val textPrimaryCol = Color.parseColor(textPrimaryHex)

                remoteViews.setInt(R.id.widget_background, "setColorFilter", bgCol)
                
                remoteViews.setInt(R.id.icon_create_daily, "setColorFilter", accentCol)
                remoteViews.setInt(R.id.icon_quick_capture, "setColorFilter", accentCol)
                remoteViews.setInt(R.id.icon_search_vault, "setColorFilter", accentCol)
                
                remoteViews.setTextColor(R.id.lbl_create_daily, textPrimaryCol)
                remoteViews.setTextColor(R.id.lbl_quick_capture, textPrimaryCol)
                remoteViews.setTextColor(R.id.lbl_search_vault, textPrimaryCol)

                // Dynamic button background contrast
                val isLight = isColorLight(bgCol)
                val btnBgRes = if (isLight) R.drawable.widget_button_bg_light else R.drawable.widget_button_bg_dark
                remoteViews.setInt(R.id.btn_create_daily, "setBackgroundResource", btnBgRes)
                remoteViews.setInt(R.id.btn_quick_capture, "setBackgroundResource", btnBgRes)
                remoteViews.setInt(R.id.btn_search_vault, "setBackgroundResource", btnBgRes)
            } catch (e: Exception) {
                // Fallbacks
                val fallbackBg = Color.parseColor("#1C1C1E")
                val fallbackAccent = Color.parseColor("#E07A5F")
                val fallbackText = Color.parseColor("#F2F2F7")
                
                remoteViews.setInt(R.id.widget_background, "setColorFilter", fallbackBg)
                remoteViews.setInt(R.id.icon_create_daily, "setColorFilter", fallbackAccent)
                remoteViews.setInt(R.id.icon_quick_capture, "setColorFilter", fallbackAccent)
                remoteViews.setInt(R.id.icon_search_vault, "setColorFilter", fallbackAccent)
                
                remoteViews.setTextColor(R.id.lbl_create_daily, fallbackText)
                remoteViews.setTextColor(R.id.lbl_quick_capture, fallbackText)
                remoteViews.setTextColor(R.id.lbl_search_vault, fallbackText)

                remoteViews.setInt(R.id.btn_create_daily, "setBackgroundResource", R.drawable.widget_button_bg_dark)
                remoteViews.setInt(R.id.btn_quick_capture, "setBackgroundResource", R.drawable.widget_button_bg_dark)
                remoteViews.setInt(R.id.btn_search_vault, "setBackgroundResource", R.drawable.widget_button_bg_dark)
            }

            // 2. Set Up Button Intent Triggers (unique requestCodes ensure intents aren't merged)
            
            // Button 1: Create Daily Note
            val intentDaily = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_action", "create_daily")
            }
            val pendingDaily = PendingIntent.getActivity(
                context,
                1,
                intentDaily,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(R.id.btn_create_daily, pendingDaily)

            // Button 2: Quick Capture
            val intentCapture = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_action", "quick_capture")
            }
            val pendingCapture = PendingIntent.getActivity(
                context,
                2,
                intentCapture,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(R.id.btn_quick_capture, pendingCapture)

            // Button 3: Search Vault
            val intentSearch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_action", "search")
            }
            val pendingSearch = PendingIntent.getActivity(
                context,
                3,
                intentSearch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(R.id.btn_search_vault, pendingSearch)

            appWidgetManager.updateAppWidget(appWidgetId, remoteViews)
        }
    }

    private fun isColorLight(color: Int): Boolean {
        val r = Color.red(color)
        val g = Color.green(color)
        val b = Color.blue(color)
        val luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
        return luminance > 0.5
    }
}
