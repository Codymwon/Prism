package com.prism.prism

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val STORAGE_CHANNEL = "com.prism.app/storage"
    private val WIDGET_CHANNEL = "com.prism.app/widget"
    
    private var pendingWidgetAction: String? = null
    private var widgetChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.getStringExtra("widget_action")
        if (action != null) {
            pendingWidgetAction = action
            widgetChannel?.invokeMethod("onWidgetAction", action)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Storage Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isExternalStorageManager" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(Environment.isExternalStorageManager())
                    } else {
                        result.success(true)
                    }
                }
                "requestExternalStorageManager" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                            val uri = Uri.fromParts("package", packageName, null)
                            intent.data = uri
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                            startActivity(intent)
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Widget Method Channel
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingWidgetAction" -> {
                    val action = pendingWidgetAction
                    pendingWidgetAction = null
                    result.success(action)
                }
                "updateWidgets" -> {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    
                    // Update Streak widget
                    val streakIds = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, StreakWidgetProvider::class.java)
                    )
                    if (streakIds.isNotEmpty()) {
                        val updateIntent = Intent(context, StreakWidgetProvider::class.java).apply {
                            setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, streakIds)
                        }
                        context.sendBroadcast(updateIntent)
                    }

                    // Update Quick Action widget
                    val quickIds = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, QuickActionWidgetProvider::class.java)
                    )
                    if (quickIds.isNotEmpty()) {
                        val updateIntent = Intent(context, QuickActionWidgetProvider::class.java).apply {
                            setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, quickIds)
                        }
                        context.sendBroadcast(updateIntent)
                    }

                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
