import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/utils.dart';
import '../notes/data/note_repository.dart';
import '../notes/presentation/providers/notes_providers.dart';

final widgetHelperProvider = Provider<WidgetHelper>((ref) {
  return WidgetHelper(ref);
});

class WidgetHelper {
  final Ref _ref;
  static const _channel = MethodChannel('com.meridian.app/widget');

  WidgetHelper(this._ref);

  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments as String?;
        if (action != null) {
          handleWidgetAction(action);
        }
      }
    });

    // Check for any pending action when the app starts
    checkPendingAction();
  }

  Future<void> checkPendingAction() async {
    try {
      final action = await _channel.invokeMethod<String>('getPendingWidgetAction');
      if (action != null && action.isNotEmpty) {
        handleWidgetAction(action);
      }
    } catch (e) {
      debugPrint('Error getting pending widget action: $e');
    }
  }

  Future<void> handleWidgetAction(String action) async {
    final router = _ref.read(appRouterProvider);
    final repo = _ref.read(noteRepositoryProvider);

    debugPrint('Handling widget action: $action');

    if (action == 'create_daily') {
      final dateStr = formatDailyDate(DateTime.now());
      // Check if daily note already exists
      final existingNote = await repo.getDailyNote(dateStr);
      if (existingNote != null) {
        router.push('/editor/${existingNote.id}?date=$dateStr');
      } else {
        final note = await repo.createNote(
          title: dateStr,
          isDaily: true,
          dailyDate: dateStr,
        );
        router.push('/editor/${note.id}?date=$dateStr&new=true');
      }
    } else if (action == 'quick_capture') {
      final note = await repo.createNote(
        title: 'Untitled',
      );
      router.push('/editor/${note.id}?new=true');
    } else if (action == 'search') {
      // Navigate to /notes first if not there
      router.go('/notes');
      // Set the search query to empty, and trigger autofocus
      _ref.read(searchQueryProvider.notifier).state = '';
      _ref.read(searchFocusProvider.notifier).state = true;
    }
  }

  static Future<void> updateWidgetData({
    required int streak,
    required bool todayReflected,
    required String bgHex,
    required String accentHex,
    required String textPrimaryHex,
    required String textSecondaryHex,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('flutter.journal_streak', streak);
      await prefs.setBool('flutter.today_reflected', todayReflected);
      
      // Theme colors
      await prefs.setString('flutter.theme_widget_bg', bgHex);
      await prefs.setString('flutter.theme_widget_accent', accentHex);
      await prefs.setString('flutter.theme_widget_text_primary', textPrimaryHex);
      await prefs.setString('flutter.theme_widget_text_secondary', textSecondaryHex);

      // Trigger native update
      await _channel.invokeMethod('updateWidgets');
      debugPrint('Widget data updated: streak=$streak, todayReflected=$todayReflected');
    } catch (e) {
      debugPrint('Error updating widget data: $e');
    }
  }
}
