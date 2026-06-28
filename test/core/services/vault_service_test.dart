import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/services/vault_service.dart';
import 'package:prism/core/database/vault_providers.dart';

class FakeWidgetRef implements WidgetRef {
  final ProviderContainer container;
  FakeWidgetRef(this.container);

  @override
  BuildContext get context => throw UnimplementedError();

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);


  @override
  T watch<T>(ProviderListenable<T> provider) {
    return container.read(provider);
  }

  @override
  void invalidate(ProviderOrFamily provider) {
    container.invalidate(provider);
  }

  @override
  bool exists(ProviderBase<Object?> provider) => true;

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {}

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    throw UnimplementedError();
  }

  @override
  T refresh<T>(Refreshable<T> provider) {
    return container.refresh(provider);
  }

  @override
  void listenSelf(void Function(Object? previous, Object? next) listener, {void Function(Object error, StackTrace stackTrace)? onError}) {}

  @override
  void onDispose(void Function() cb) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late Directory tempDir;
  late FakeWidgetRef fakeRef;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('prism_test_hub');
    container = ProviderContainer();
    fakeRef = FakeWidgetRef(container);
  });

  tearDown(() async {
    container.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VaultManagementService.changeBaseDirectory Tests', () {
    test('should append Prism Hub to the selected directory if not already present', () async {
      final service = container.read(vaultManagementServiceProvider);
      final selectedPath = tempDir.path;
      final expectedHubPath = p.join(selectedPath, 'Prism Hub');

      // Call the method under test
      await service.changeBaseDirectory(newPath: selectedPath, ref: fakeRef);

      // Verify baseVaultsDirectoryProvider is updated to the aligned path
      final baseDir = await container.read(baseVaultsDirectoryProvider.future);
      expect(baseDir, equals(expectedHubPath));

      // Verify it created a default vault inside the aligned path
      final defaultVaultPath = p.join(expectedHubPath, 'My Vault');
      expect(await Directory(defaultVaultPath).exists(), isTrue);

      // Verify SharedPreferences has the aligned path
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('baseVaultsDirectory'), equals(expectedHubPath));
      expect(prefs.getString('activeVaultName'), equals('My Vault'));
    });

    test('should not append Prism Hub if the selected directory is already named Prism Hub', () async {
      final service = container.read(vaultManagementServiceProvider);

      // Create a directory named 'Prism Hub' inside our temp dir
      final hubDir = Directory(p.join(tempDir.path, 'Prism Hub'));
      await hubDir.create();

      final selectedPath = hubDir.path;

      // Call the method under test
      await service.changeBaseDirectory(newPath: selectedPath, ref: fakeRef);

      // Verify baseVaultsDirectoryProvider is updated to the selected path without appending another 'Prism Hub'
      final baseDir = await container.read(baseVaultsDirectoryProvider.future);
      expect(baseDir, equals(selectedPath));

      // Verify SharedPreferences has the selected path
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('baseVaultsDirectory'), equals(selectedPath));
    });

    test('should select the most recently modified vault if multiple vaults exist', () async {
      final service = container.read(vaultManagementServiceProvider);
      
      // Create a Prism Hub directory
      final hubDir = Directory(p.join(tempDir.path, 'Prism Hub'));
      await hubDir.create();

      // Create two vaults
      final vault1 = Directory(p.join(hubDir.path, 'Vault1'));
      final vault2 = Directory(p.join(hubDir.path, 'Vault2'));
      await vault1.create();
      await vault2.create();

      final dbFile1 = File(p.join(vault1.path, '.prism.db'));
      final dbFile2 = File(p.join(vault2.path, '.prism.db'));
      await dbFile1.writeAsString('vault1 db');
      await dbFile2.writeAsString('vault2 db');

      // Set dbFile2 modification time to the future (e.g., 10 minutes from now)
      // to make it explicitly newer than any directory creation timestamps.
      final futureTime = DateTime.now().add(const Duration(minutes: 10));
      await dbFile2.setLastModified(futureTime);

      // Call the method under test
      await service.changeBaseDirectory(newPath: hubDir.path, ref: fakeRef);

      // Verify the active vault is vault2 (most recently modified)
      final activeVault = await container.read(activeVaultNameProvider.future);
      expect(activeVault, equals('Vault2'));

      // Verify SharedPreferences has the correct active vault
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeVaultName'), equals('Vault2'));
    });
  });
}
