import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:prism/core/services/data_deletion_service.dart' hide secureStorageProvider;
import 'package:prism/core/services/two_way_sync_service.dart';
import 'package:prism/features/settings/presentation/screens/security_settings_screen.dart';

class InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data;

  InMemorySecureStorage([Map<String, String>? initial]) : _data = initial != null ? Map.from(initial) : {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }
}

class MockDataDeletionService extends Fake implements DataDeletionService {
  bool executeFullResetCalled = false;

  @override
  Future<void> executeFullReset() async {
    executeFullResetCalled = true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'analyticsEnabled': false,
    });
  });

  Widget buildTestableWidget({
    required FlutterSecureStorage secureStorage,
    DataDeletionService? dataDeletionService,
  }) {
    final router = GoRouter(
      initialLocation: '/settings/security',
      routes: [
        GoRoute(
          path: '/settings/security',
          builder: (context, state) => const SecuritySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/cloud-sync',
          builder: (context, state) => const Scaffold(body: Text('Cloud Sync Screen')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(secureStorage),
        if (dataDeletionService != null)
          dataDeletionServiceProvider.overrideWithValue(dataDeletionService),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders Security Trust Center hero, SQLCipher status, and PBKDF2 specs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemorySecureStorage();
    await tester.pumpWidget(buildTestableWidget(secureStorage: storage));
    await tester.pumpAndSettle();

    // Verify Title & Hero
    expect(find.text('Security Trust Center'), findsNWidgets(2)); // AppBar + Hero
    expect(find.text('ON-DEVICE STORAGE LOCK'), findsOneWidget);
    expect(find.text('AES-256-CBC Active'), findsOneWidget);
    expect(find.text('On-Device Storage Lock (AES-256)'), findsOneWidget);

    // Verify Passphrase Unconfigured state
    expect(find.text('MASTER ENCRYPTION PASSPHRASE'), findsOneWidget);
    expect(find.text('Not Configured'), findsOneWidget);
    expect(find.text('Set Master Passphrase'), findsOneWidget);

    // Verify PBKDF2 specifications
    expect(find.text('PBKDF2 Key Derivation'), findsOneWidget);
    expect(find.text('HMAC-SHA256 • 100,000 iterations • 256-bit key'), findsOneWidget);
  });

  testWidgets('sets a new master passphrase and updates status to Passphrase Configured', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemorySecureStorage();
    await tester.pumpWidget(buildTestableWidget(secureStorage: storage));
    await tester.pumpAndSettle();

    // Tap Set Master Passphrase
    await tester.tap(find.text('Set Master Passphrase'));
    await tester.pumpAndSettle();

    expect(find.text('Set Master Passphrase'), findsNWidgets(2)); // title in dialog
    expect(find.text('New Passphrase'), findsOneWidget);
    expect(find.text('Confirm New Passphrase'), findsOneWidget);

    // Enter matching passphrases
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));
    await tester.enterText(textFields.at(0), 'secret-key-123');
    await tester.enterText(textFields.at(1), 'secret-key-123');
    await tester.pumpAndSettle();

    // Tap Save Passphrase
    await tester.tap(find.text('Save Passphrase'));
    await tester.pumpAndSettle();

    // Dialog dismissed and status updated
    expect(find.text('Passphrase Configured'), findsOneWidget);
    expect(find.text('Test Passphrase Integrity'), findsOneWidget);
    expect(find.text('Change Master Passphrase'), findsOneWidget);
    expect(await storage.read(key: 'sync_passphrase'), 'secret-key-123');
  });

  testWidgets('verifies master passphrase integrity with correct and incorrect entry', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemorySecureStorage({'sync_passphrase': 'valid-passphrase'});
    await tester.pumpWidget(buildTestableWidget(secureStorage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Passphrase Configured'), findsOneWidget);
    expect(find.text('Test Passphrase Integrity'), findsOneWidget);

    // 1. Verify with incorrect passphrase
    await tester.tap(find.text('Test Passphrase Integrity'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Passphrase'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'wrong-passphrase');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Passphrase incorrect. Cryptographic key root does not match.'), findsOneWidget);

    // 2. Verify with correct passphrase
    await tester.tap(find.text('Test Passphrase Integrity'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'valid-passphrase');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Passphrase verified! Cryptographic key root is valid.'), findsOneWidget);
  });

  testWidgets('navigates to cloud sync from quick jump tile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemorySecureStorage();
    await tester.pumpWidget(buildTestableWidget(secureStorage: storage));
    await tester.pumpAndSettle();

    final cloudSyncTile = find.text('Google Drive Cloud Sync');
    await tester.scrollUntilVisible(cloudSyncTile, 300);
    await tester.pumpAndSettle();

    await tester.tap(cloudSyncTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Cloud Sync Screen'), findsOneWidget);
  });

  testWidgets('displays Danger Zone and requires typing DELETE to wipe all data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemorySecureStorage();
    final mockDeletionService = MockDataDeletionService();

    await tester.pumpWidget(buildTestableWidget(
      secureStorage: storage,
      dataDeletionService: mockDeletionService,
    ));
    await tester.pumpAndSettle();

    final deleteTile = find.text('Delete All Data & Reset');
    await tester.scrollUntilVisible(deleteTile, 500);
    await tester.pumpAndSettle();

    expect(find.text('DANGER ZONE'), findsOneWidget);
    expect(deleteTile, findsOneWidget);

    await tester.tap(deleteTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Delete All Data & Reset?'), findsOneWidget);
    final deleteButton = find.widgetWithText(ElevatedButton, 'Delete Everything');
    expect(tester.widget<ElevatedButton>(deleteButton).enabled, isFalse);

    // Enter wrong text
    await tester.enterText(find.byType(TextField), 'del');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(deleteButton).enabled, isFalse);

    // Enter DELETE
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(deleteButton).enabled, isTrue);

    await tester.tap(deleteButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(mockDeletionService.executeFullResetCalled, isTrue);
    expect(find.text('Onboarding Screen'), findsOneWidget);
  });
}
