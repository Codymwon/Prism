import 'package:google_fonts/google_fonts.dart';
import 'package:prism/l10n/l10n.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';
import 'package:prism/features/onboarding/presentation/widgets/vault_setup_form.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/shared/design_system/buttons.dart';
import 'package:prism/core/config/app_config.dart';

// ---------------------------------------------------------------------------
// Stub Riverpod notifiers – no SharedPreferences, no DB, no platform channels
// ---------------------------------------------------------------------------

class _FakeOnboardingState extends OnboardingState {
  @override
  bool build() {
    return false;
  }

  @override
  Future<void> completeOnboarding() async {
    state = true;
  }
}

/// Replaces BaseVaultsDirectory – never reads/writes SharedPreferences.
class _FakeBaseVaultsDirectory extends BaseVaultsDirectory {
  @override
  Future<String> build() async => '';

  @override
  Future<void> setDirectory(String path) async {}
}

/// Replaces ActiveVaultName – never reads/writes SharedPreferences.
class _FakeActiveVaultName extends ActiveVaultName {
  @override
  Future<String> build() async => 'My Vault';

  @override
  Future<void> setVaultName(String name) async {}
}

// ---------------------------------------------------------------------------
// Provider overrides – swap real providers for fakes in every test
// ---------------------------------------------------------------------------
final _providerOverrides = <Override>[
  onboardingStateProvider
      .overrideWith(() => _FakeOnboardingState()),
  baseVaultsDirectoryProvider
      .overrideWith(() => _FakeBaseVaultsDirectory()),
  activeVaultNameProvider
      .overrideWith(() => _FakeActiveVaultName()),
];

// ---------------------------------------------------------------------------
// Stub FilePicker – returns a fixed path without touching the OS
// ---------------------------------------------------------------------------
class _StubFilePicker extends FilePicker {
  final String path;
  _StubFilePicker(this.path);

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      path;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _buildForm({
  required String pickerPath,
  required VoidCallback onStartSetup,
  Future<void> Function(String, String, String)? onPersist,
  VoidCallback? onEndSetup,
}) {
  FilePicker.platform = _StubFilePicker(pickerPath);
  return ProviderScope(
    overrides: _providerOverrides,
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VaultSetupForm(
          onStartSetup: onStartSetup,
          onEndSetup: onEndSetup ?? () {},
          onPersist: onPersist ?? (_, _, _) async {},
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late Directory tempDir;

  setUp(() {
    AppConfig.enableExternalStorage = true;
    // Only mock the storage-permission channel – it is called unconditionally
    // before any other logic, and is the only remaining platform channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.prism.app/storage'),
      (call) async {
        if (call.method == 'isExternalStorageManager') return true;
        return null;
      },
    );

    // Mock path_provider channel for getApplicationDocumentsDirectory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return p.join(tempDir.path, 'documents');
        }
        return null;
      },
    );

    tempDir = Directory.systemTemp.createTempSync('prism_test_');
    GoogleFonts.config.allowRuntimeFetching = false;

    // Intercept asset loading to load google_fonts from the local directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(message.buffer.asUint8List());
        if (key == 'AssetManifest.json') {
          final manifest = {
            'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
            'google_fonts/Inter-Medium.ttf': ['google_fonts/Inter-Medium.ttf'],
            'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
            'google_fonts/Inter-SemiBold.ttf': ['google_fonts/Inter-SemiBold.ttf'],
            'google_fonts/RobotoMono-Regular.ttf': ['google_fonts/RobotoMono-Regular.ttf'],
            'google_fonts/Inter-ExtraBold.ttf': ['google_fonts/Inter-ExtraBold.ttf'],
          };
          final jsonStr = json.encode(manifest);
          final bytes = utf8.encode(jsonStr);
          return ByteData.view(Uint8List.fromList(bytes).buffer);
        }
        if (key == 'AssetManifest.bin') {
          final manifest = {
            'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
            'google_fonts/Inter-Medium.ttf': ['google_fonts/Inter-Medium.ttf'],
            'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
            'google_fonts/Inter-SemiBold.ttf': ['google_fonts/Inter-SemiBold.ttf'],
            'google_fonts/RobotoMono-Regular.ttf': ['google_fonts/RobotoMono-Regular.ttf'],
            'google_fonts/Inter-ExtraBold.ttf': ['google_fonts/Inter-ExtraBold.ttf'],
          };
          return const StandardMessageCodec().encodeMessage(manifest);
        }

        if (key.endsWith('.ttf')) {
          var filename = p.basename(key);
          if (filename == 'Inter-ExtraBold.ttf') {
            filename = 'Inter-Bold.ttf'; // Fallback to Inter-Bold in test environment
          }
          final file = File('google_fonts/$filename');
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            return ByteData.view(bytes.buffer);
          }
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── Test 1: initial render ─────────────────────────────────────────────────
  testWidgets('renders Step 1 and hides Step 2 initially',
      (WidgetTester tester) async {
    _setViewport(tester);

    await tester.pumpWidget(_buildForm(
      pickerPath: tempDir.path,
      onStartSetup: () {},
    ));
    await tester.pumpAndSettle();

    expect(find.text('Workspace Storage Location'), findsOneWidget);
    expect(find.text('Prism Hub Name'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Workspace Name'), findsNothing);
    expect(find.text('Confirm & Begin'), findsNothing);
  });

  // ── Test 2: new hub → Step 1 → Step 2 → Step 3 → Confirm ────────────────
  testWidgets('new hub: Step 1 → Step 2 → Step 3 → onStartSetup called',
      (WidgetTester tester) async {
    _setViewport(tester);

    bool startCalled = false;
    bool persistCalled = false;

    await tester.pumpWidget(_buildForm(
      pickerPath: tempDir.path,
      onStartSetup: () => startCalled = true,
      onPersist: (_, _, _) async => persistCalled = true,
    ));
    await tester.pumpAndSettle();

    // Pick a folder
    await tester.tap(find.text('Tap to choose a folder'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Location selected'), findsOneWidget);

    // Step 1 -> Step 2
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Name your first workspace'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Step 2 -> Step 3
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Privacy & Diagnostics'), findsOneWidget);
    expect(find.text('Confirm & Begin'), findsOneWidget);

    // Confirm -> creates vault dir + calls onPersist
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(startCalled, isTrue);
    expect(persistCalled, isTrue);
    expect(
      Directory(p.join(tempDir.path, 'Prism Hub', 'My Workspace')).existsSync(),
      isTrue,
    );
  });

  // ── Test 3: existing hub → auto-import, skip Step 2, show Step 3 ─────────
  testWidgets('existing hub: auto-imports, skips Step 2, shows Step 3',
      (WidgetTester tester) async {
    _setViewport(tester);

    bool startCalled = false;
    String? importedVault;

    // All real I/O (directory creation + setLastModified) must run inside
    // runAsync so it doesn't suspend in the fake_async zone.
    await tester.runAsync(() async {
      final hubDir = Directory(p.join(tempDir.path, 'Prism Hub'))..createSync();
      final vaultA = Directory(p.join(hubDir.path, 'Vault A'))..createSync();
      final vaultB = Directory(p.join(hubDir.path, 'Vault B'))..createSync();

      final dbA = File(p.join(vaultA.path, '.prism.db'))..writeAsStringSync('a');
      final dbB = File(p.join(vaultB.path, '.prism.db'))..writeAsStringSync('b');
      await dbA.setLastModified(DateTime.now().subtract(const Duration(hours: 1)));
      await dbB.setLastModified(DateTime.now().add(const Duration(hours: 1)));
    });

    await tester.pumpWidget(_buildForm(
      pickerPath: tempDir.path,
      onStartSetup: () => startCalled = true,
      onPersist: (_, vault, _) async => importedVault = vault,
    ));
    await tester.pumpAndSettle();

    // Pick the parent folder
    await tester.tap(find.text('Tap to choose a folder'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Next → detects existing vaults, transitions to Step 3, skips Step 2
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text('Name your first workspace'), findsNothing); // Step 2 skipped
    expect(find.text('Privacy & Diagnostics'), findsOneWidget); // Shows privacy preferences
    expect(find.text('Confirm & Begin'), findsOneWidget);

    // Confirm & Begin -> completes auto-import
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(startCalled, isTrue);
    expect(importedVault, equals('Vault B')); // most recently modified
  });

  // ── Test 4: storage location options toggling ──────────────────────────────
  testWidgets('renders storage type cards and toggles visibility of fields',
      (WidgetTester tester) async {
    _setViewport(tester);

    await tester.pumpWidget(_buildForm(
      pickerPath: tempDir.path,
      onStartSetup: () {},
    ));
    await tester.pumpAndSettle();

    // Verify both options are present
    expect(find.text('Device storage'), findsOneWidget);
    expect(find.text('App storage'), findsOneWidget);

    // Default: Device storage is selected, Hub Name and Folder Picker are visible
    expect(find.text('Prism Hub Name'), findsOneWidget);
    expect(find.text('Select Folder Location'), findsOneWidget);

    // Tap App storage card
    await tester.tap(find.text('App storage'));
    await tester.pumpAndSettle();

    // Now Hub Name and Folder Picker should be hidden
    expect(find.text('Prism Hub Name'), findsNothing);
    expect(find.text('Select Folder Location'), findsNothing);
  });

  // ── Test 5: complete onboarding via sandbox app storage ───────────────────
  testWidgets('completing onboarding via App storage sandbox flow',
      (WidgetTester tester) async {
    _setViewport(tester);

    bool startCalled = false;
    String? persistedHubPath;
    String? persistedVaultName;
    String? persistedVaultType;

    await tester.pumpWidget(_buildForm(
      pickerPath: tempDir.path,
      onStartSetup: () => startCalled = true,
      onPersist: (hub, vault, type) async {
        persistedHubPath = hub;
        persistedVaultName = vault;
        persistedVaultType = type;
      },
    ));
    await tester.pumpAndSettle();

    // Select App storage
    await tester.tap(find.text('App storage'));
    await tester.pumpAndSettle();

    // Tap Next (Step 1 -> Step 2)
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Name your first workspace'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next (Step 2 -> Step 3)
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Privacy & Diagnostics'), findsOneWidget);
    expect(find.text('Confirm & Begin'), findsOneWidget);

    // Tap Confirm & Begin
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(startCalled, isTrue);
    expect(persistedVaultType, equals('sandbox'));
    expect(persistedVaultName, equals('My Workspace'));
    // Since it resolves path_provider, it should contain a sandbox documents path
    expect(persistedHubPath, contains('prism_vaults'));
  });

  // ── Test 6: Step 3 telemetry toggle defaults to false (strict opt-in) ───────
  testWidgets('Step 3 telemetry toggle defaults to false for strict opt-in',
      (WidgetTester tester) async {
    _setViewport(tester);

    await tester.pumpWidget(_buildForm(
      pickerPath: tempDir.path,
      onStartSetup: () {},
    ));
    await tester.pumpAndSettle();

    // Select App storage and advance to Step 2
    await tester.tap(find.text('App storage'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Advance to Step 3 (Privacy & Diagnostics)
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Privacy & Diagnostics'), findsOneWidget);

    // Verify Switch is present and its value is false (strict opt-in)
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Toggle the switch to ON
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final toggledSwitch = tester.widget<Switch>(switchFinder);
    expect(toggledSwitch.value, isTrue);
  });

  testWidgets('v1.0 release: skips storage selection step when enableExternalStorage is false', (tester) async {
    _setViewport(tester);
    AppConfig.enableExternalStorage = false;

    String? persistedHub;
    String? persistedVault;
    String? persistedType;

    await tester.pumpWidget(_buildForm(
      pickerPath: '/not/used',
      onStartSetup: () {},
      onPersist: (hub, vault, type) async {
        persistedHub = hub;
        persistedVault = vault;
        persistedType = type;
      },
    ));
    await tester.pumpAndSettle();

    // Step 1 storage options should NOT be shown
    expect(find.text('Device storage'), findsNothing);
    expect(find.text('App storage'), findsNothing);

    // Should immediately render Step 2: Workspace/Vault Name
    expect(find.text('Name your first workspace'), findsOneWidget);
    // Back button to Step 1 should NOT be visible
    expect(find.text('Back'), findsNothing);

    // Advance to Step 3 (Privacy)
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Privacy & Diagnostics'), findsOneWidget);

    // Complete onboarding
    await tester.runAsync(() async {
      await tester.tap(find.byType(DesignPrimaryButton));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify sandbox persistence
    expect(persistedType, equals('sandbox'));
    expect(persistedVault, isNotEmpty);
    expect(persistedHub, contains('prism_vaults'));
  });
}
