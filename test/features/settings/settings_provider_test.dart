import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/settings/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Settings Providers - Unit Tests', () {
    test('autoCreateDailyNoteOnLaunchProvider defaults and sets correctly', () async {
      // 1. Check default
      final defaultVal = await container.read(autoCreateDailyNoteOnLaunchProvider.future);
      expect(defaultVal, isFalse);

      // 2. Set value
      await container.read(autoCreateDailyNoteOnLaunchProvider.notifier).setEnabled(true);
      
      // 3. Verify state and SharedPreferences
      final newVal = await container.read(autoCreateDailyNoteOnLaunchProvider.future);
      expect(newVal, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoCreateDailyNoteOnLaunch'), isTrue);
    });

    test('startOfWeekProvider defaults and sets correctly', () async {
      // 1. Check default
      final defaultVal = await container.read(startOfWeekProvider.future);
      expect(defaultVal, equals('Sunday'));

      // 2. Set value
      await container.read(startOfWeekProvider.notifier).setStartOfWeek('Monday');

      // 3. Verify state and SharedPreferences
      final newVal = await container.read(startOfWeekProvider.future);
      expect(newVal, equals('Monday'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('startOfWeek'), equals('Monday'));
    });

    test('lineNumbersGutterProvider defaults and sets correctly', () async {
      // 1. Check default
      final defaultVal = await container.read(lineNumbersGutterProvider.future);
      expect(defaultVal, isFalse);

      // 2. Set value
      await container.read(lineNumbersGutterProvider.notifier).setEnabled(true);

      // 3. Verify state and SharedPreferences
      final newVal = await container.read(lineNumbersGutterProvider.future);
      expect(newVal, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lineNumbersGutter'), isTrue);
    });

    test('autoPairBracketsProvider defaults and sets correctly', () async {
      // 1. Check default
      final defaultVal = await container.read(autoPairBracketsProvider.future);
      expect(defaultVal, isTrue);

      // 2. Set value
      await container.read(autoPairBracketsProvider.notifier).setEnabled(false);

      // 3. Verify state and SharedPreferences
      final newVal = await container.read(autoPairBracketsProvider.future);
      expect(newVal, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoPairBrackets'), isFalse);
    });
  });
}
