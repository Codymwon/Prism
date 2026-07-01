import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prism/core/services/google_drive_service.dart';
import 'package:prism/core/services/two_way_sync_service.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/core/services/vault_service.dart';
import 'package:prism/features/settings/presentation/screens/cloud_sync_screen.dart';

class FakeGoogleDriveService extends Fake implements GoogleDriveService {
  bool signedIn = false;
  GoogleSignInAccount? mockUser;

  @override
  bool get isSignedIn => signedIn;

  @override
  GoogleSignInAccount? get currentUser => mockUser;

  @override
  Future<Either<GoogleDriveFailure, Unit>> signIn() async {
    signedIn = true;
    return const Right(unit);
  }

  @override
  Future<Either<GoogleDriveFailure, Unit>> signOut() async {
    signedIn = false;
    return const Right(unit);
  }

  @override
  Future<Either<GoogleDriveFailure, Unit>> signInSilently() async {
    return const Right(unit);
  }
}

class FakeTwoWaySyncService extends Fake implements TwoWaySyncService {
  bool configured = false;
  bool deleteCalled = false;
  String? deletedVault;

  @override
  Future<bool> isSyncConfigured() async => configured;

  @override
  Future<Either<SyncFailure, Unit>> configureSync({required String passphrase}) async {
    configured = true;
    return const Right(unit);
  }

  @override
  Future<Either<SyncFailure, Unit>> deleteVaultCloudData(String vaultName) async {
    deleteCalled = true;
    deletedVault = vaultName;
    return const Right(unit);
  }
}

class FakeSyncedVaults extends SyncedVaults {
  final List<String> _synced;
  FakeSyncedVaults(this._synced);

  @override
  Future<List<String>> build() async => _synced;

  @override
  Future<void> enableSync(String vaultName) async {}

  @override
  Future<void> disableSync(String vaultName) async {}
}

class MockGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  String get email => 'test@example.com';
}

void main() {
  testWidgets('CloudSyncScreen shows Connect Google Drive when not signed in', (tester) async {
    final fakeDrive = FakeGoogleDriveService();
    final fakeSync = FakeTwoWaySyncService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleDriveServiceProvider.overrideWithValue(fakeDrive),
          twoWaySyncServiceProvider.overrideWithValue(fakeSync),
        ],
        child: const MaterialApp(
          home: CloudSyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connect Google Drive'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
  });

  testWidgets('CloudSyncScreen shows Connected account and passphrase setup when signed in but not configured', (tester) async {
    final fakeDrive = FakeGoogleDriveService()
      ..signedIn = true
      ..mockUser = MockGoogleSignInAccount();
    final fakeSync = FakeTwoWaySyncService()..configured = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleDriveServiceProvider.overrideWithValue(fakeDrive),
          twoWaySyncServiceProvider.overrideWithValue(fakeSync),
        ],
        child: const MaterialApp(
          home: CloudSyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Enable Sync & Encryption'), findsOneWidget);
    expect(find.text('End-to-End Encryption Active'), findsNothing);
  });

  testWidgets('CloudSyncScreen shows vaults list and toggle switches when signed in and configured', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeDrive = FakeGoogleDriveService()
      ..signedIn = true
      ..mockUser = MockGoogleSignInAccount();
    final fakeSync = FakeTwoWaySyncService()..configured = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleDriveServiceProvider.overrideWithValue(fakeDrive),
          twoWaySyncServiceProvider.overrideWithValue(fakeSync),
          availableVaultsProvider.overrideWith((ref) => ['Vault A', 'Vault B']),
          syncedVaultsProvider.overrideWith(() => FakeSyncedVaults(['Vault A'])),
        ],
        child: const MaterialApp(
          home: CloudSyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('End-to-End Encryption Active'), findsOneWidget);
    expect(find.text('Vault A'), findsOneWidget);
    expect(find.text('Vault B'), findsOneWidget);
    
    // Verify switch states
    final switchListTiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    expect(switchListTiles.length, equals(2));
    expect(switchListTiles.first.value, isTrue); // Vault A is synced
    expect(switchListTiles.last.value, isFalse); // Vault B is local only
  });
}
