import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../database/vault_providers.dart';
import 'google_drive_service.dart';
import '../../features/onboarding/data/onboarding_provider.dart';
import '../../features/onboarding/data/tutorial_provider.dart';
import '../../features/subscription/presentation/providers/subscription_providers.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dataDeletionHttpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final dataDeletionServiceProvider = Provider<DataDeletionService>((ref) {
  return DataDeletionService(
    ref,
    secureStorage: ref.watch(secureStorageProvider),
    httpClient: ref.watch(dataDeletionHttpClientProvider),
  );
});

/// Service responsible for executing complete, irreversible account and data deletion
/// complying with Apple App Store Review Guideline 5.1.1(v) and Google Play Data Safety Policy.
class DataDeletionService {
  final Ref ref;
  final DatabaseHelper _databaseHelper;
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  DataDeletionService(
    this.ref, {
    DatabaseHelper? databaseHelper,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  /// Executes a full, permanent factory reset and data purge:
  /// 1. Closes the active SQLite database to release all native locks.
  /// 2. Deletes all local vault markdown files, databases, and audio attachments.
  /// 3. Clears temporary files and application cache.
  /// 4. Wipes all keys stored in encrypted FlutterSecureStorage.
  /// 5. Revokes Google Drive OAuth credentials.
  /// 6. Deletes customer record from RevenueCat via REST API (if secret key configured)
  ///    and resets the anonymous subscriber ID via Purchases.logOut().
  /// 7. Clears all SharedPreferences settings, telemetry flags, and tutorial states.
  /// 8. Resets in-memory Riverpod notifiers to redirect navigation to Onboarding.
  Future<void> executeFullReset() async {
    // 1. Close active database
    try {
      await _databaseHelper.closeDatabase();
    } catch (e) {
      debugPrint('[DataDeletionService] Error closing database: $e');
    }

    // 2. Wipe physical vault directories
    try {
      final baseDir = await ref.read(baseVaultsDirectoryProvider.future);
      if (baseDir.isNotEmpty) {
        final dir = Directory(baseDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('[DataDeletionService] Error deleting base vaults directory: $e');
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final defaultVaultsDir = Directory(p.join(docDir.path, 'prism_vaults'));
      if (await defaultVaultsDir.exists()) {
        await defaultVaultsDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[DataDeletionService] Error deleting sandbox vaults directory: $e');
    }

    // 3. Clear temporary files and application cache
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint('[DataDeletionService] Error deleting temp item: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[DataDeletionService] Error accessing temp directory: $e');
    }

    // 4. Wipe encrypted secure storage
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('[DataDeletionService] Error deleting secure storage: $e');
    }

    // 5. Revoke Google Drive OAuth access token
    try {
      final driveService = ref.read(googleDriveServiceProvider);
      await driveService.disconnect();
    } catch (e) {
      debugPrint('[DataDeletionService] Error disconnecting Google Drive: $e');
    }

    // 6. Delete RevenueCat subscriber record and log out
    try {
      final clientWrapper = ref.read(revenueCatClientWrapperProvider);
      final isConfigured = await clientWrapper.isConfigured();
      if (isConfigured) {
        try {
          final customerInfo = await clientWrapper.getCustomerInfo();
          final appUserId = customerInfo.originalAppUserId;
          const secretKey = String.fromEnvironment('REVENUECAT_SECRET_KEY');
          if (secretKey.isNotEmpty && appUserId.isNotEmpty) {
            final uri = Uri.parse('https://api.revenuecat.com/v1/subscribers/$appUserId');
            await _httpClient.delete(
              uri,
              headers: {
                'Authorization': 'Bearer $secretKey',
                'Content-Type': 'application/json',
              },
            ).timeout(const Duration(seconds: 5));
          }
        } catch (apiErr) {
          debugPrint('[DataDeletionService] RevenueCat REST delete error: $apiErr');
        }
        await clientWrapper.logOut();
      }
    } catch (e) {
      debugPrint('[DataDeletionService] Error logging out of RevenueCat: $e');
    }

    // 7. Reset in-memory notifiers
    try {
      await ref.read(onboardingStateProvider.notifier).resetOnboarding();
      await ref.read(tutorialStateProvider.notifier).resetTutorial();
      await ref.read(editorTutorialStateProvider.notifier).resetTutorial();
      await ref.read(journalTutorialStateProvider.notifier).resetTutorial();
    } catch (e) {
      debugPrint('[DataDeletionService] Error resetting notifiers: $e');
    }

    // 8. Clear all SharedPreferences
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.clear();
    } catch (e) {
      debugPrint('[DataDeletionService] Error clearing SharedPreferences: $e');
    }
  }
}
