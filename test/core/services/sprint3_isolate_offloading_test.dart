import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/services/analytics_service.dart';
import 'package:prism/core/services/sync_encryption_service.dart';
import 'package:prism/core/services/vault_export_service.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

class _FakeNoteRepository implements NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestableSvc extends VaultExportServiceImpl {
  final String saveTo;
  _TestableSvc(super.ref, {required this.saveTo});

  @override
  Future<String?> saveBytes(String fileName, List<int> bytes) async {
    final out = File(p.join(saveTo, fileName));
    await out.writeAsBytes(bytes);
    return out.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncEncryptionService Isolate Offloading', () {
    final service = SyncEncryptionService();

    test('deriveKey runs via Isolate.run and derives a functioning SecretKey', () async {
      final salt = service.generateSalt();
      const passphrase = 'SuperSecretPassphrase2026!';

      final keyResult = await service.deriveKey(
        passphrase: passphrase,
        salt: salt,
      );

      expect(keyResult.isRight(), isTrue);
      final key = keyResult.getOrElse((_) => throw Exception('Failed to derive key'));

      // Encrypt and decrypt a test payload
      final originalText = 'Sprint 3 Isolate Offloading Test Note';
      final originalBytes = Uint8List.fromList(utf8.encode(originalText));

      final encryptResult = await service.encryptBytes(
        bytes: originalBytes,
        key: key,
      );
      expect(encryptResult.isRight(), isTrue);
      final encryptedBytes = encryptResult.getOrElse((_) => throw Exception('Encryption failed'));

      final decryptResult = await service.decryptBytes(
        encryptedBytes: encryptedBytes,
        key: key,
      );
      expect(decryptResult.isRight(), isTrue);
      final decryptedBytes = decryptResult.getOrElse((_) => throw Exception('Decryption failed'));
      expect(utf8.decode(decryptedBytes), equals(originalText));
    });
  });

  group('VaultExportService Isolate ZIP Archiving', () {
    late Directory tempDir;
    late Directory saveDir;
    late Directory vaultDir;
    late SharedPreferences prefs;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sprint3_export_test_');
      saveDir = await Directory(p.join(tempDir.path, 'saves')).create();
      vaultDir = await Directory(p.join(tempDir.path, 'My Vault')).create();

      SharedPreferences.setMockInitialValues({
        'baseVaultsDirectory': tempDir.path,
        'activeVaultName': 'My Vault',
      });
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Reads files directly in worker isolate and produces valid ZIP', () async {
      // Create mock vault structure: notes and audio attachments
      final note1 = File(p.join(vaultDir.path, 'Note 1.md'));
      await note1.writeAsString('# Note 1 Content\nHello world.');

      final note2 = File(p.join(vaultDir.path, 'Note 2.md'));
      await note2.writeAsString('# Note 2 Content\nSprint 3 verified.');

      final attachmentsDir = Directory(p.join(vaultDir.path, 'attachments'));
      await attachmentsDir.create(recursive: true);
      final audioFile = File(p.join(attachmentsDir.path, 'recording.m4a'));
      await audioFile.writeAsBytes(List.filled(1024, 42)); // 1KB audio mock

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          noteRepositoryProvider.overrideWithValue(_FakeNoteRepository()),
          vaultExportServiceProvider.overrideWith(
            (ref) => _TestableSvc(ref, saveTo: saveDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final exportService = container.read(vaultExportServiceProvider);

      final result = await exportService.export(
        ExportFormat.zipArchive,
        onProgress: (progress, label) {},
      );

      expect(result.isRight(), isTrue,
          reason: 'Expected Right but got: ${result.getLeft().toNullable()}');
      final exportResult = result.getRight().toNullable()!;
      expect(exportResult.noteCount, equals(2));

      // Verify ZIP contents
      final zipFile = File(exportResult.savedPath);
      expect(await zipFile.exists(), isTrue);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final archiveFileNames = archive.files.map((f) => f.name).toSet();

      expect(archiveFileNames.contains('Note 1.md'), isTrue);
      expect(archiveFileNames.contains('Note 2.md'), isTrue);
      expect(archiveFileNames.contains('attachments/recording.m4a'), isTrue);
    });
  });

  group('AnalyticsService Static Buffer Capping', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'analyticsEnabled': true});
      final prefs = await SharedPreferences.getInstance();
      AnalyticsService.initialize(prefs);
      AnalyticsService.clearLogs();
    });

    tearDown(() {
      AnalyticsService.clearLogs();
    });

    test('Caps loggedEvents at maxLoggedItems (200) with FIFO eviction', () async {
      expect(AnalyticsService.loggedEvents, isEmpty);

      // Log 250 distinct events
      for (int i = 0; i < 250; i++) {
        await AnalyticsService.logEvent('event_$i', parameters: {'index': i});
      }

      // Buffer should be strictly capped at 200
      expect(AnalyticsService.loggedEvents.length, equals(200));

      // Oldest 50 events (event_0 .. event_49) should have been evicted
      expect(AnalyticsService.loggedEvents.first['name'], equals('event_50'));
      expect(AnalyticsService.loggedEvents.last['name'], equals('event_249'));
    });

    test('Caps loggedErrors at maxLoggedItems (200) with FIFO eviction', () async {
      expect(AnalyticsService.loggedErrors, isEmpty);

      // Log 250 distinct errors
      for (int i = 0; i < 250; i++) {
        await AnalyticsService.logError(Exception('error_$i'), null);
      }

      // Buffer should be strictly capped at 200
      expect(AnalyticsService.loggedErrors.length, equals(200));

      // Oldest 50 errors should have been evicted
      expect(AnalyticsService.loggedErrors.first['exception'].toString(), contains('error_50'));
      expect(AnalyticsService.loggedErrors.last['exception'].toString(), contains('error_249'));
    });
  });
}
