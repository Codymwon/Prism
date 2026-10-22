import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prism/core/services/data_deletion_service.dart';
import 'package:prism/core/services/google_drive_service.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';
import 'package:prism/features/subscription/data/datasources/revenuecat_client_wrapper.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';

class FakeCustomerInfo extends Fake implements CustomerInfo {
  @override
  String get originalAppUserId => 'anon_user_123';
}

class MockRevenueCatClientWrapper extends Fake implements RevenueCatClientWrapper {
  bool isConfiguredValue = true;
  bool logOutCalled = false;
  CustomerInfo? mockCustomerInfo;

  @override
  Future<bool> isConfigured() async => isConfiguredValue;

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    return mockCustomerInfo ?? FakeCustomerInfo();
  }

  @override
  Future<CustomerInfo> logOut() async {
    logOutCalled = true;
    return mockCustomerInfo ?? FakeCustomerInfo();
  }
}

class FakeGoogleDriveService extends Fake implements GoogleDriveService {
  bool disconnectCalled = false;

  @override
  Future<Either<GoogleDriveFailure, Unit>> disconnect() async {
    disconnectCalled = true;
    return const Right(unit);
  }
}

class MockSecureStorage extends Fake implements FlutterSecureStorage {
  bool deleteAllCalled = false;

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deleteAllCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;
  late SharedPreferences testPrefs;
  late MockRevenueCatClientWrapper mockRevenueCat;
  late FakeGoogleDriveService fakeGoogleDrive;
  late MockSecureStorage mockSecureStorage;
  late ProviderContainer container;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('prism_deletion_test_');
    SharedPreferences.setMockInitialValues({
      'hasOnboarded': true,
      'baseVaultsDirectory': tempTestDir.path,
      'activeVaultName': 'Personal',
      'themeType': 'sepia',
    });
    testPrefs = await SharedPreferences.getInstance();

    mockRevenueCat = MockRevenueCatClientWrapper();
    fakeGoogleDrive = FakeGoogleDriveService();
    mockSecureStorage = MockSecureStorage();

    final mockHttp = MockClient((request) async {
      return http.Response('{"status": "deleted"}', 200);
    });

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(testPrefs),
        googleDriveServiceProvider.overrideWithValue(fakeGoogleDrive),
        revenueCatClientWrapperProvider.overrideWithValue(mockRevenueCat),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        dataDeletionHttpClientProvider.overrideWithValue(mockHttp),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  test('executeFullReset deletes vault files, clears secure storage, revokes drive and resets state', () async {
    // 1. Create a dummy file in the temp test vault directory
    final vaultDir = Directory(p.join(tempTestDir.path, 'Personal'));
    await vaultDir.create(recursive: true);
    final dummyNote = File(p.join(vaultDir.path, 'note1.md'));
    await dummyNote.writeAsString('# Hello World');
    expect(await dummyNote.exists(), isTrue);

    final service = container.read(dataDeletionServiceProvider);

    // Verify initial state
    expect(testPrefs.getBool('hasOnboarded'), isTrue);
    expect(container.read(onboardingStateProvider), isTrue);

    // 3. Execute full reset
    await service.executeFullReset();

    // 4. Verify local files deleted
    expect(await dummyNote.exists(), isFalse);
    expect(await vaultDir.exists(), isFalse);

    // 5. Verify secure storage wiped
    expect(mockSecureStorage.deleteAllCalled, isTrue);

    // 6. Verify Google Drive disconnected
    expect(fakeGoogleDrive.disconnectCalled, isTrue);

    // 7. Verify RevenueCat logged out
    expect(mockRevenueCat.logOutCalled, isTrue);

    // 8. Verify SharedPreferences cleared
    expect(testPrefs.getKeys().isEmpty, isTrue);

    // 9. Verify onboarding state reset to false
    expect(container.read(onboardingStateProvider), isFalse);
  });
}
