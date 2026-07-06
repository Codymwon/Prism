import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static SharedPreferences? _prefs;

  static void initialize(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // Test visibility properties to inspect logged events in unit tests
  @visibleForTesting
  static final List<Map<String, dynamic>> loggedEvents = [];

  @visibleForTesting
  static final List<Map<String, dynamic>> loggedErrors = [];

  static Future<bool> isEnabled() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return prefs.getBool('analyticsEnabled') ?? true;
    } catch (_) {
      return true; // Default to true if SharedPreferences is not initialized
    }
  }

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    if (kDebugMode) {
      debugPrint('Analytics: event logged -> $name with params: $parameters');
    }

    // Cache locally for test inspections
    loggedEvents.add({
      'name': name,
      'parameters': parameters,
    });

    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging analytics event to Firebase: $e');
    }
  }

  static Future<void> logError(dynamic exception, StackTrace? stack, {bool fatal = false}) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    if (kDebugMode) {
      debugPrint('Analytics: error logged -> $exception');
    }

    loggedErrors.add({
      'exception': exception,
      'stack': stack,
      'fatal': fatal,
    });

    try {
      await FirebaseCrashlytics.instance.recordError(exception, stack, fatal: fatal);
    } catch (e) {
      debugPrint('Error logging crashlytics error to Firebase: $e');
    }
  }

  // Clear mock logs for testing
  @visibleForTesting
  static void clearLogs() {
    loggedEvents.clear();
    loggedErrors.clear();
  }
}
