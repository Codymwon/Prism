import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/settings/presentation/screens/support_screen.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/features/subscription/data/datasources/revenuecat_client_wrapper.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

class FakeCustomerInfo extends Fake implements CustomerInfo {
  final Map<String, EntitlementInfo> _mockActiveEntitlements;
  @override
  final String originalAppUserId;

  FakeCustomerInfo(this._mockActiveEntitlements, {this.originalAppUserId = 'RC-Anon-123'});

  @override
  EntitlementInfos get entitlements => FakeEntitlementInfos(_mockActiveEntitlements);
}

class FakeEntitlementInfos extends Fake implements EntitlementInfos {
  @override
  final Map<String, EntitlementInfo> active;

  FakeEntitlementInfos(this.active);
}

class MockRevenueCatClientWrapper extends Fake implements RevenueCatClientWrapper {
  final CustomerInfo customerInfo;
  MockRevenueCatClientWrapper(this.customerInfo);

  @override
  Future<CustomerInfo> getCustomerInfo() async => customerInfo;
}

class _FakeBaseVaultsDirectory extends BaseVaultsDirectory {
  final String path;
  _FakeBaseVaultsDirectory(this.path);

  @override
  Future<String> build() async => path;

  @override
  Future<void> setDirectory(String path) async {}
}

class _FakeActiveVaultName extends ActiveVaultName {
  final String name;
  _FakeActiveVaultName(this.name);

  @override
  Future<String> build() async => name;

  @override
  Future<void> setVaultName(String name) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late MockRevenueCatClientWrapper mockWrapper;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('prism_test_support_screen_');
    SharedPreferences.setMockInitialValues({
      'vaultType': 'sandbox',
    });
    prefs = await SharedPreferences.getInstance();

    PackageInfo.setMockInitialValues(
      appName: 'Prism',
      packageName: 'com.prism.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'buildSignature',
    );

    final info = FakeCustomerInfo(const {}, originalAppUserId: 'RC-Anon-123');
    mockWrapper = MockRevenueCatClientWrapper(info);

    // Create a mock note in the temp directory to simulate vault stats
    final file = File(p.join(tempDir.path, 'MyVault', 'test_note.md'));
    await file.create(recursive: true);
    await file.writeAsString('# Hello World');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildScreen({required bool isPro}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        baseVaultsDirectoryProvider.overrideWith(() => _FakeBaseVaultsDirectory(tempDir.path)),
        activeVaultNameProvider.overrideWith(() => _FakeActiveVaultName('MyVault')),
        revenueCatClientWrapperProvider.overrideWithValue(mockWrapper),
        isProProvider.overrideWithValue(isPro),
      ],
      child: const MaterialApp(
        home: SupportScreen(),
      ),
    );
  }

  void _setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('renders SupportScreen with form fields and updates selection', (WidgetTester tester) async {
    _setViewport(tester);
    await tester.pumpWidget(buildScreen(isPro: false));
    await tester.pump();

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 350));
    });
    await tester.pump();

    // Verify Title & Subtitle
    expect(find.text('Contact Support'), findsOneWidget);
    expect(find.text('How can we help you?'), findsOneWidget);

    // Verify Category options
    expect(find.text('🐛  Report a Bug'), findsOneWidget);

    // Verify Fields
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Attach System Diagnostics'), findsOneWidget);
  });

  testWidgets('toggling Attach System Diagnostics hides and shows diagnostics card', (WidgetTester tester) async {
    _setViewport(tester);
    await tester.pumpWidget(buildScreen(isPro: true));
    await tester.pump();

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 350));
    });
    await tester.pump();

    // Verify Diagnostics Preview is visible initially
    expect(find.text('Diagnostics Preview'), findsOneWidget);
    expect(find.textContaining('Vault Type: sandbox'), findsOneWidget);
    expect(find.textContaining('Notes Count: 1'), findsOneWidget);
    expect(find.textContaining('Pro Active: Yes'), findsOneWidget);
    expect(find.textContaining('User ID: RC-Anon-123'), findsOneWidget);

    // Toggle switch off
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Verify Diagnostics Preview is hidden
    expect(find.text('Diagnostics Preview'), findsNothing);
  });

  testWidgets('form validation triggers error when fields are empty', (WidgetTester tester) async {
    _setViewport(tester);
    await tester.pumpWidget(buildScreen(isPro: false));
    await tester.pump();

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 350));
    });
    await tester.pump();

    // Tap submit button directly (ensure visible first in scroll view)
    final submitFinder = find.text('Send Support Request');
    await tester.ensureVisible(submitFinder);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(submitFinder, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Verify validation error text
    expect(find.text('Please enter a subject.'), findsOneWidget);
    expect(find.text('Please enter details for your request.'), findsOneWidget);
  });
}
