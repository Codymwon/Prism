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
        
        // Theme Colors
        val bgHex = prefs.getString("flutter.theme_widget_bg", "#18181C")
        val accentHex = prefs.getString("flutter.theme_widget_accent", "#7C6FF7")
        val textPrimaryHex = prefs.getString("flutter.theme_widget_text_primary", "#FFFFFF")

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
            } catch (e: Exception) {
                // Fallbacks
                remoteViews.setInt(R.id.widget_background, "setColorFilter", Color.parseColor("#18181C"))
                val defaultAccent = Color.parseColor("#7C6FF7")
                remoteViews.setInt(R.id.icon_create_daily, "setColorFilter", defaultAccent)
                remoteViews.setInt(R.id.icon_quick_capture, "setColorFilter", defaultAccent)
                remoteViews.setInt(R.id.icon_search_vault, "setColorFilter", defaultAccent)
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
}
