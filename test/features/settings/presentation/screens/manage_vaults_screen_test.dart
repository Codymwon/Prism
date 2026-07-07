import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:prism/features/settings/presentation/screens/manage_vaults_screen.dart';
import 'package:prism/core/services/vault_service.dart';
import 'package:prism/core/database/vault_providers.dart';

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

class FakeVaultManagementService extends VaultManagementService {
  String? lastNewPath;
  String? lastVaultType;
  bool? lastMigrateData;
  bool throwError = false;

  @override
  Future<void> changeStorageLocation({
    required String newPath,
    required String vaultType,
    required bool migrateData,
    required WidgetRef ref,
  }) async {
    if (throwError) {
      throw const FileSystemException('Migration failed simulated');
    }
    lastNewPath = newPath;
    lastVaultType = vaultType;
    lastMigrateData = migrateData;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late FakeVaultManagementService mockService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('prism_test_manage_vaults_');
    mockService = FakeVaultManagementService();

    // Mock path_provider MethodChannel
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        vaultManagementServiceProvider.overrideWithValue(mockService),
        baseVaultsDirectoryProvider.overrideWith(() => _FakeBaseVaultsDirectory(tempDir.path)),
        activeVaultNameProvider.overrideWith(() => _FakeActiveVaultName('My Vault')),
        availableVaultsProvider.overrideWith((ref) => Future.value(['My Vault'])),
      ],
      child: const MaterialApp(
        home: ManageVaultsScreen(),
      ),
    );
  }

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('renders ManageVaultsScreen and opens relocation bottom sheet', (WidgetTester tester) async {
    setViewport(tester);
    FilePicker.platform = _StubFilePicker(p.join(tempDir.path, 'new_location'));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('PHYSICAL STORAGE LOCATION'), findsOneWidget);
    expect(find.text('Relocate Prism Hub'), findsOneWidget);

    // Tap Relocate Prism Hub
    await tester.tap(find.text('Relocate Prism Hub'));
    await tester.pumpAndSettle();

    // Verify bottom sheet is displayed
    expect(find.text('Relocate Vault Location'), findsOneWidget);
    expect(find.text('Device storage'), findsOneWidget);
    expect(find.text('App storage'), findsOneWidget);
    expect(find.text('Migrate existing notes to new location'), findsOneWidget);
    expect(find.text('Confirm Relocation'), findsOneWidget);

    // Toggle App storage
    await tester.tap(find.text('App storage'));
    await tester.pumpAndSettle();

    // Tap Confirm Relocation
    await tester.tap(find.text('Confirm Relocation'));
    await tester.pumpAndSettle();

    // Verify service was called with sandbox and migrateData
    expect(mockService.lastVaultType, equals('sandbox'));
    expect(mockService.lastNewPath, contains('prism_vaults'));
  });
}
