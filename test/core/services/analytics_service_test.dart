import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/services/analytics_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AnalyticsService.clearLogs();
  });

  Future<void> setupPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    AnalyticsService.initialize(prefs);
  }

  group('AnalyticsService Consent and Event Logging Tests', () {
    test('Logs events when analytics is enabled (default)', () async {
      await setupPrefs({}); // Defaults to enabled (true)

      await AnalyticsService.logEvent(
        'test_event',
        parameters: {'key': 'value'},
      );

      expect(AnalyticsService.loggedEvents, hasLength(1));
      expect(AnalyticsService.loggedEvents.first['name'], equals('test_event'));
      expect(AnalyticsService.loggedEvents.first['parameters'], equals({'key': 'value'}));
    });

    test('Does not log events when analytics is disabled', () async {
      await setupPrefs({'analyticsEnabled': false});

      await AnalyticsService.logEvent('test_event');

      expect(AnalyticsService.loggedEvents, isEmpty);
    });

    test('Logs errors when analytics is enabled (default)', () async {
      await setupPrefs({}); // Defaults to enabled (true)

      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;
      await AnalyticsService.logError(exception, stackTrace, fatal: true);

      expect(AnalyticsService.loggedErrors, hasLength(1));
      expect(AnalyticsService.loggedErrors.first['exception'], equals(exception));
      expect(AnalyticsService.loggedErrors.first['stack'], equals(stackTrace));
      expect(AnalyticsService.loggedErrors.first['fatal'], isTrue);
    });

    test('Does not log errors when analytics is disabled', () async {
      await setupPrefs({'analyticsEnabled': false});

      await AnalyticsService.logError(Exception('Test exception'), null);

      expect(AnalyticsService.loggedErrors, isEmpty);
    });

    test('Correctly captures change_theme event with theme name parameter', () async {
      await setupPrefs({});

      await AnalyticsService.logEvent('change_theme', parameters: {'theme': 'midnight'});

      expect(AnalyticsService.loggedEvents, hasLength(1));
      expect(AnalyticsService.loggedEvents.first['name'], equals('change_theme'));
      expect(AnalyticsService.loggedEvents.first['parameters'], equals({'theme': 'midnight'}));
    });

    test('Correctly captures change_editor_mode event with view mode parameter', () async {
      await setupPrefs({});

      await AnalyticsService.logEvent('change_editor_mode', parameters: {'mode': 'livePreview'});

      expect(AnalyticsService.loggedEvents, hasLength(1));
      expect(AnalyticsService.loggedEvents.first['name'], equals('change_editor_mode'));
      expect(AnalyticsService.loggedEvents.first['parameters'], equals({'mode': 'livePreview'}));
    });

    test('Correctly captures insert_macro event with macro label parameter', () async {
      await setupPrefs({});

      await AnalyticsService.logEvent('insert_macro', parameters: {'macro_label': 'Todo List'});

      expect(AnalyticsService.loggedEvents, hasLength(1));
      expect(AnalyticsService.loggedEvents.first['name'], equals('insert_macro'));
      expect(AnalyticsService.loggedEvents.first['parameters'], equals({'macro_label': 'Todo List'}));
    });

    test('Correctly captures sync_run event with status and details parameters', () async {
      await setupPrefs({});

      await AnalyticsService.logEvent('sync_run', parameters: {
        'status': 'success',
        'uploaded': 3,
        'downloaded': 5,
      });

      expect(AnalyticsService.loggedEvents, hasLength(1));
      expect(AnalyticsService.loggedEvents.first['name'], equals('sync_run'));
      expect(AnalyticsService.loggedEvents.first['parameters'], equals({
        'status': 'success',
        'uploaded': 3,
        'downloaded': 5,
      }));
    });

    test('Correctly captures perform_search event', () async {
      await setupPrefs({});

      await AnalyticsService.logEvent('perform_search');

      expect(AnalyticsService.loggedEvents, hasLength(1));
      expect(AnalyticsService.loggedEvents.first['name'], equals('perform_search'));
    });
  });
}
