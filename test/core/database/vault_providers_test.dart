import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

void main() {
  late Directory tempDir;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_vault_providers_test');
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': tempDir.path,
    });
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('syncedVaultsProvider starts empty, enables and disables sync, and persists to json', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Keep the provider alive
    container.listen(syncedVaultsProvider, (_, _) {});

    // Wait for the provider to build
    final initialList = await container.read(syncedVaultsProvider.future);
    expect(initialList, isEmpty);

    // Enable sync for Vault A
    await container.read(syncedVaultsProvider.notifier).enableSync('Vault A');

    final listAfterEnable = await container.read(syncedVaultsProvider.future);
    expect(listAfterEnable, equals(['Vault A']));

    // Verify file is created
    final configFile = File(p.join(tempDir.path, '.prism', 'sync_config.json'));
    expect(await configFile.exists(), isTrue);

    final fileContent = await configFile.readAsString();
    final data = jsonDecode(fileContent) as Map<String, dynamic>;
    expect(data['syncedVaults'], equals(['Vault A']));

    // Enable sync for Vault B
    await container.read(syncedVaultsProvider.notifier).enableSync('Vault B');
    final listAfterEnableTwo = await container.read(syncedVaultsProvider.future);
    expect(listAfterEnableTwo, equals(['Vault A', 'Vault B']));

    // Disable sync for Vault A
    await container.read(syncedVaultsProvider.notifier).disableSync('Vault A');
    final listAfterDisable = await container.read(syncedVaultsProvider.future);
    expect(listAfterDisable, equals(['Vault B']));

    final fileContentAfterDisable = await configFile.readAsString();
    final dataAfterDisable = jsonDecode(fileContentAfterDisable) as Map<String, dynamic>;
    expect(dataAfterDisable['syncedVaults'], equals(['Vault B']));
  });

  test('syncedVaultsProvider loads existing configuration on startup', () async {
    // Manually write a config file first
    final configDir = Directory(p.join(tempDir.path, '.prism'));
    await configDir.create(recursive: true);
    final configFile = File(p.join(configDir.path, 'sync_config.json'));
    await configFile.writeAsString(jsonEncode({
      'version': 1,
      'syncedVaults': ['PreExisting Vault'],
    }));

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final list = await container.read(syncedVaultsProvider.future);
    expect(list, equals(['PreExisting Vault']));
  });
}
