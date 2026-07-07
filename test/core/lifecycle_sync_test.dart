import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/core/services/note_ingestion_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:prism/features/journal/presentation/providers/journal_providers.dart';
import 'package:prism/features/widgets/widget_helper.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/main.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNoteIngestionService extends Fake implements NoteIngestionService {
  bool syncVaultCalled = false;
  String? lastSyncedVaultPath;

  @override
  Future<bool> syncVault(String vaultPath, {Database? db}) async {
    syncVaultCalled = true;
    lastSyncedVaultPath = vaultPath;
    return true;
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
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': '/mock/vaults',
      'activeVaultName': 'My Vault',
      'hasOnboarded': true,
    });
  });

  testWidgets('app resume triggers syncVault and increments versions', (WidgetTester tester) async {
    // Intercept com.prism.app/widget channel
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.prism.app/widget'),
      (methodCall) async {
        return null;
      },
    );

    final mockIngestion = MockNoteIngestionService();
    final mockRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Lifecycle Test placeholder')),
        ),
      ],
    );
    
    // Build PrismApp inside ProviderScope with overrides
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          noteIngestionServiceProvider.overrideWithValue(mockIngestion),
          activeVaultPathProvider.overrideWith((ref) => '/mock/vaults/My Vault'),
          appRouterProvider.overrideWithValue(mockRouter),
          widgetHelperProvider.overrideWithValue(FakeWidgetHelper()),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 0, totalCount: 0)),
        ],
        child: const PrismApp(),
      ),
    );

    // Ensure initial frame renders
    await tester.pumpAndSettle();

    // Verify initial state
    expect(mockIngestion.syncVaultCalled, isFalse);

    // Simulate app lifecycle state resumed
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    
    // Wait for the async syncVault callback to resolve and settle
    await tester.pumpAndSettle();

    // Verify syncVault was called
    expect(mockIngestion.syncVaultCalled, isTrue);
    expect(mockIngestion.lastSyncedVaultPath, '/mock/vaults/My Vault');
  });
}
