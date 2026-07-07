import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/platform/widget_helper.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/main.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  @override
  bool get isOpen => true;

  @override
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    return [];
  }
}

class FakeWidgetHelper extends Fake implements WidgetHelper {
  @override
  void init() {}

  @override
  Future<void> updateWidgetData({
    required int streak,
    required bool todayReflected,
    required String bgHex,
    required String accentHex,
    required String textPrimaryHex,
    required String textSecondaryHex,
  }) async {}
}

void main() {
  late GoRouter mockRouter;

  setUp(() {
    // Intercept com.prism.app/widget channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.prism.app/widget'),
      (methodCall) async {
        return null;
      },
    );

    mockRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Placeholder')),
        ),
      ],
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.prism.app/widget'),
      null,
    );
  });

  testWidgets('databaseProvider is NOT initialized at startup if hasOnboarded is false', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'hasOnboarded': false,
    });

    bool databaseProviderInitialized = false;

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Listen to databaseProvider to detect initialization
          databaseProvider.overrideWith((ref) async {
            databaseProviderInitialized = true;
            return FakeDatabase();
          }),
          appRouterProvider.overrideWithValue(mockRouter),
          widgetHelperProvider.overrideWithValue(FakeWidgetHelper()),
          // NOTE: We do NOT override journalStreakProvider or allDailyDatesProvider here,
          // allowing the real providers to run and depend on databaseProvider.future
        ],
        child: const PrismApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify database was NOT initialized (Expect failure here in RED phase)
    expect(databaseProviderInitialized, isFalse);
  });

  testWidgets('databaseProvider IS initialized at startup if hasOnboarded is true', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'hasOnboarded': true,
    });

    bool databaseProviderInitialized = false;

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async {
            databaseProviderInitialized = true;
            return FakeDatabase();
          }),
          appRouterProvider.overrideWithValue(mockRouter),
          widgetHelperProvider.overrideWithValue(FakeWidgetHelper()),
        ],
        child: const PrismApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify database WAS initialized
    expect(databaseProviderInitialized, isTrue);
  });
}
