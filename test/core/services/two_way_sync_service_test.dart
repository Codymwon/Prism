import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/services/google_drive_service.dart';
import 'package:prism/core/services/sync_encryption_service.dart';
import 'package:prism/core/services/two_way_sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGoogleDriveService extends Fake implements GoogleDriveService {
  final Map<String, List<int>> files = {};
  final Map<String, DateTime> modifiedTimes = {};
  bool listFilesCalled = false;

  @override
  bool get isSignedIn => true;

  @override
  Future<Either<GoogleDriveFailure, List<drive.File>>> listFiles() async {
    listFilesCalled = true;
    final list = files.entries.map((e) {
      return drive.File()
        ..id = e.key
        ..name = e.key
        ..modifiedTime = modifiedTimes[e.key] ?? DateTime.parse('2026-06-20T00:00:00Z')
        ..mimeType = 'application/octet-stream';
    }).toList();
    return Right(list);
  }

  @override
  Future<Either<GoogleDriveFailure, drive.File>> uploadFile(
    String name,
    List<int> bytes, {
    String? mimeType,
  }) async {
    files[name] = bytes;
    modifiedTimes[name] = DateTime.now();
    return Right(drive.File()
      ..id = name
      ..name = name);
  }

  @override
  Future<Either<GoogleDriveFailure, Uint8List>> downloadFile(String fileId) async {
    if (!files.containsKey(fileId)) {
      return Left(GoogleDriveFileNotFoundFailure('File not found'));
    }
    return Right(Uint8List.fromList(files[fileId]!));
  }

  @override
  Future<Either<GoogleDriveFailure, drive.File>> updateFile(
    String fileId,
    List<int> bytes, {
    String? mimeType,
  }) async {
    files[fileId] = bytes;
    modifiedTimes[fileId] = DateTime.now();
    return Right(drive.File()
      ..id = fileId
      ..name = fileId);
  }

  @override
  Future<Either<GoogleDriveFailure, Unit>> deleteFile(String fileId) async {
    if (!files.containsKey(fileId)) {
      return Left(GoogleDriveFileNotFoundFailure('File not found'));
    }
    files.remove(fileId);
    modifiedTimes.remove(fileId);
    return const Right(unit);
  }
}

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> storage = {};

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
    if (value == null) {
      storage.remove(key);
    } else {
      storage[key] = value;
    }
  }

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
    return storage[key];
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
    return storage.containsKey(key);
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeGoogleDriveService mockDriveService;
  late FakeFlutterSecureStorage mockSecureStorage;
  late Directory tempHubDir;
  late Directory tempVaultDir;
  late ProviderContainer container;
  late String prefix;

  setUp(() async {
    mockDriveService = FakeGoogleDriveService();
    mockSecureStorage = FakeFlutterSecureStorage();
    
    // Create an isolated hub directory
    tempHubDir = Directory.systemTemp.createTempSync('prism_hub_test');
    tempVaultDir = Directory(p.join(tempHubDir.path, 'my_vault'))..createSync();
    
    final baseDir = tempHubDir.path;
    final vaultName = p.basename(tempVaultDir.path);
    SharedPreferences.setMockInitialValues({
      'welcomeNotesSeeded_${tempVaultDir.path.hashCode}': true,
      'baseVaultsDirectory': baseDir,
      'activeVaultName': vaultName,
    });

    container = ProviderContainer(
      overrides: [
        googleDriveServiceProvider.overrideWithValue(mockDriveService),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        activeVaultPathProvider.overrideWith((ref) => tempVaultDir.path),
      ],
    );

    // Enable sync by default for all existing tests
    container.listen(syncedVaultsProvider, (_, __) {});
    await container.read(syncedVaultsProvider.notifier).enableSync(vaultName);

    final vaultHash = (await container.read(syncEncryptionServiceProvider).hashVaultName(vaultName)).getOrElse((_) => throw Exception());
    prefix = '${vaultHash}_';
  });

  tearDown(() {
    container.dispose();
    try {
      if (tempHubDir.existsSync()) {
        tempHubDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('TwoWaySyncService - Cycle 1: Sync Configuration', () {
    test('configureSync generates a new salt, uploads it to Drive, and stores the passphrase', () async {
      final syncService = container.read(twoWaySyncServiceProvider);

      expect(await syncService.isSyncConfigured(), isFalse);

      final result = await syncService.configureSync(passphrase: 'super-secret-password');
      expect(result.isRight(), isTrue);

      final savedPass = await mockSecureStorage.read(key: 'sync_passphrase');
      expect(savedPass, equals('super-secret-password'));

      expect(mockDriveService.files.containsKey('sync_salt.json'), isTrue);
      final saltJsonBytes = mockDriveService.files['sync_salt.json']!;
      final saltData = jsonDecode(utf8.decode(saltJsonBytes)) as Map<String, dynamic>;
      expect(saltData.containsKey('salt'), isTrue);

      expect(await syncService.isSyncConfigured(), isTrue);
    });
  });

  group('TwoWaySyncService - Cycle 2: Initial Uploads', () {
    test('runSync scans local vault, encrypts contents, and uploads them to Drive', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Setup sync configuration (simulate previous configuration)
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      // 2. Create local notes, attachments, templates, and metadata
      final noteFile = File(p.join(tempVaultDir.path, 'note1.md'));
      noteFile.writeAsStringSync('--- \ntitle: "Note 1"\n---\nHello World');

      final attachDir = Directory(p.join(tempVaultDir.path, 'attachments'))..createSync();
      final attachFile = File(p.join(attachDir.path, 'recording.m4a'));
      attachFile.writeAsBytesSync([10, 20, 30, 40]);

      final templateDir = Directory(p.join(tempVaultDir.path, 'templates'))..createSync();
      final templateFile = File(p.join(templateDir.path, 'template1.md'));
      templateFile.writeAsStringSync('--- \ntitle: "Template 1"\n---\nTemplate body');

      final metadataFile = File(p.join(tempVaultDir.path, '.prism-metadata.json'));
      metadataFile.writeAsStringSync('{"version":1}');

      // 3. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));
      expect(result.uploaded, equals(4));

      // 4. Verify local manifest was created
      final manifestFile = File(p.join(tempVaultDir.path, '.prism', 'sync_manifest.json'));
      expect(manifestFile.existsSync(), isTrue);

      final manifestData = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifestData.containsKey('files'), isTrue);
      final manifestFiles = manifestData['files'] as Map<String, dynamic>;
      expect(manifestFiles.length, equals(4));

      // 5. Verify encrypted files on mock Google Drive
      final derivedKeyResult = await encryptionService.deriveKey(passphrase: passphrase, salt: salt);
      final derivedKey = derivedKeyResult.getOrElse((_) => throw Exception('Failed to derive key'));

      // Check each file on drive by computing its expected SHA-256 name hash
      final expectedPaths = [
        'note1.md',
        'attachments/recording.m4a',
        'templates/template1.md',
        '.prism-metadata.json',
      ];

      for (final relPath in expectedPaths) {
        final pathHash = (await encryptionService.hashFilePath(relPath)).getOrElse((_) => throw Exception('Failed path hash'));
        expect(mockDriveService.files.containsKey('$prefix$pathHash'), isTrue);

        // Download, decrypt, and decode to verify path and content
        final encryptedBytes = mockDriveService.files['$prefix$pathHash']!;
        final decryptedResult = await encryptionService.decryptBytes(encryptedBytes: encryptedBytes, key: derivedKey);
        expect(decryptedResult.isRight(), isTrue);

        final decryptedBytes = decryptedResult.getOrElse((_) => throw Exception('Decrypt failed'));

        // Decode format: [4-byte path length] + [UTF-8 path] + [file content]
        final pathLen = decryptedBytes.buffer.asByteData().getUint32(0, Endian.big);
        final decodedPath = utf8.decode(decryptedBytes.sublist(4, 4 + pathLen));
        final fileContentBytes = decryptedBytes.sublist(4 + pathLen);

        expect(decodedPath, equals(relPath));

        if (relPath == 'note1.md') {
          expect(utf8.decode(fileContentBytes), equals('--- \ntitle: "Note 1"\n---\nHello World'));
        } else if (relPath == 'attachments/recording.m4a') {
          expect(fileContentBytes, equals([10, 20, 30, 40]));
        } else if (relPath == 'templates/template1.md') {
          expect(utf8.decode(fileContentBytes), equals('--- \ntitle: "Template 1"\n---\nTemplate body'));
        } else if (relPath == '.prism-metadata.json') {
          expect(utf8.decode(fileContentBytes), equals('{"version":1}'));
        }
      }
    });
  });

  group('TwoWaySyncService - Cycle 3: Initial Downloads', () {
    Future<Uint8List> packAndEncrypt(String relPath, List<int> fileBytes, SecretKey key, SyncEncryptionService encryptionService) async {
      final pathBytes = utf8.encode(relPath);
      final payload = Uint8List(4 + pathBytes.length + fileBytes.length);
      payload.buffer.asByteData().setUint32(0, pathBytes.length, Endian.big);
      payload.setRange(4, 4 + pathBytes.length, pathBytes);
      payload.setRange(4 + pathBytes.length, payload.length, fileBytes);
      final encryptResult = await encryptionService.encryptBytes(bytes: payload, key: key);
      return encryptResult.getOrElse((_) => throw Exception('Encrypt failed'));
    }

    test('runSync downloads encrypted files from Drive, decrypts, and writes them to local disk', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Setup sync configuration
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      final derivedKeyResult = await encryptionService.deriveKey(passphrase: passphrase, salt: salt);
      final derivedKey = derivedKeyResult.getOrElse((_) => throw Exception('Failed to derive key'));

      // 2. Prepare mock Google Drive files
      final remoteFilesData = {
        'note2.md': utf8.encode('--- \ntitle: "Note 2"\n---\nRemote note body'),
        'attachments/image2.png': [100, 101, 102],
        'templates/meeting.md': utf8.encode('--- \ntitle: "Meeting Template"\n---\nMeeting body'),
        '.prism-metadata.json': utf8.encode('{"version":1,"custom_folders":[]}'),
      };

      for (final relPath in remoteFilesData.keys) {
        final fileBytes = remoteFilesData[relPath]!;
        final pathHash = (await encryptionService.hashFilePath(relPath)).getOrElse((_) => throw Exception('Failed path hash'));
        final encrypted = await packAndEncrypt(relPath, fileBytes, derivedKey, encryptionService);
        mockDriveService.files['$prefix$pathHash'] = encrypted;
      }

      // 3. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));
      expect(result.downloaded, equals(4));

      // 4. Verify local files were created with correct content
      final note2File = File(p.join(tempVaultDir.path, 'note2.md'));
      expect(note2File.existsSync(), isTrue);
      expect(note2File.readAsStringSync(), equals('--- \ntitle: "Note 2"\n---\nRemote note body'));

      final image2File = File(p.join(tempVaultDir.path, 'attachments', 'image2.png'));
      expect(image2File.existsSync(), isTrue);
      expect(image2File.readAsBytesSync(), equals([100, 101, 102]));

      final templateFile = File(p.join(tempVaultDir.path, 'templates', 'meeting.md'));
      expect(templateFile.existsSync(), isTrue);
      expect(templateFile.readAsStringSync(), equals('--- \ntitle: "Meeting Template"\n---\nMeeting body'));

      final metadataFile = File(p.join(tempVaultDir.path, '.prism-metadata.json'));
      expect(metadataFile.existsSync(), isTrue);
      expect(metadataFile.readAsStringSync(), equals('{"version":1,"custom_folders":[]}'));

      // 5. Verify manifest tracks these files
      final manifestFile = File(p.join(tempVaultDir.path, '.prism', 'sync_manifest.json'));
      expect(manifestFile.existsSync(), isTrue);

      final manifestData = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final manifestFiles = manifestData['files'] as Map<String, dynamic>;
      expect(manifestFiles.length, equals(4));
      expect(manifestFiles.containsKey('note2.md'), isTrue);
      expect(manifestFiles.containsKey('attachments/image2.png'), isTrue);
    });
  });

  group('TwoWaySyncService - Cycle 4: Local & Remote Modifications', () {
    Future<Uint8List> packAndEncrypt(String relPath, List<int> fileBytes, SecretKey key, SyncEncryptionService encryptionService) async {
      final pathBytes = utf8.encode(relPath);
      final payload = Uint8List(4 + pathBytes.length + fileBytes.length);
      payload.buffer.asByteData().setUint32(0, pathBytes.length, Endian.big);
      payload.setRange(4, 4 + pathBytes.length, pathBytes);
      payload.setRange(4 + pathBytes.length, payload.length, fileBytes);
      final encryptResult = await encryptionService.encryptBytes(bytes: payload, key: key);
      return encryptResult.getOrElse((_) => throw Exception('Encrypt failed'));
    }

    test('runSync uploads locally modified files to Google Drive', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Setup sync configuration
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      final derivedKeyResult = await encryptionService.deriveKey(passphrase: passphrase, salt: salt);
      final derivedKey = derivedKeyResult.getOrElse((_) => throw Exception('Failed to derive key'));

      // 2. Create a local file and its manifest entry as if it was synced in the past
      final relPath = 'note_mod.md';
      final localFile = File(p.join(tempVaultDir.path, relPath));
      localFile.writeAsStringSync('Content A');
      final t1 = DateTime.now().subtract(const Duration(hours: 1));
      localFile.setLastModifiedSync(t1);

      final hashA = await encryptionService.hashFilePath(relPath).then((r) => r.getOrElse((_) => throw Exception()));
      final encryptedA = await packAndEncrypt('noteA.md', utf8.encode('Content A'), derivedKey, encryptionService);
      mockDriveService.files['$prefix$hashA'] = encryptedA;

      final r1 = DateTime.now().subtract(const Duration(hours: 1));
      mockDriveService.modifiedTimes['$prefix$hashA'] = r1;

      final manifestDir = Directory(p.join(tempVaultDir.path, '.prism'))..createSync();
      final manifestFile = File(p.join(manifestDir.path, 'sync_manifest.json'));
      final contentAHash = await calculateContentHash('Content A');
      final manifestPayload = {
        'version': 1,
        'files': {
          relPath: {
            'fileHash': contentAHash,
            'lastSyncedModifiedTime': t1.millisecondsSinceEpoch,
            'googleDriveFileId': hashA,
            'remoteModifiedTime': r1.millisecondsSinceEpoch,
          }
        }
      };
      manifestFile.writeAsStringSync(jsonEncode(manifestPayload));

      // 3. Edit local file (local content hash changes and modification time becomes t2)
      localFile.writeAsStringSync('Content B');
      final t2 = DateTime.now();
      localFile.setLastModifiedSync(t2);

      // 4. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));
      expect(result.uploaded, equals(1));
      expect(result.downloaded, equals(0));

      // 5. Verify the updated manifest and drive contents
      final updatedManifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final manifestFiles = updatedManifest['files'] as Map<String, dynamic>;
      expect(manifestFiles[relPath]['lastSyncedModifiedTime'], equals(localFile.statSync().modified.millisecondsSinceEpoch));

      final driveEncryptedBytes = mockDriveService.files['$prefix$hashA']!;
      final decryptResult = await encryptionService.decryptBytes(encryptedBytes: driveEncryptedBytes, key: derivedKey);
      expect(decryptResult.isRight(), isTrue);
      final decryptedPayload = decryptResult.getOrElse((_) => Uint8List(0));
      final pathLen = decryptedPayload.buffer.asByteData().getUint32(0, Endian.big);
      final fileContentBytes = decryptedPayload.sublist(4 + pathLen);
      expect(utf8.decode(fileContentBytes), equals('Content B'));
    });

    test('runSync downloads remotely modified files from Google Drive and updates local files', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Setup sync configuration
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      final derivedKeyResult = await encryptionService.deriveKey(passphrase: passphrase, salt: salt);
      final derivedKey = derivedKeyResult.getOrElse((_) => throw Exception('Failed to derive key'));

      // 2. Create local file and manifest entry representing Synced state of Content A
      final relPath = 'note_remote_mod.md';
      final localFile = File(p.join(tempVaultDir.path, relPath));
      localFile.writeAsStringSync('Content A');
      final t1 = DateTime.now().subtract(const Duration(hours: 1));
      localFile.setLastModifiedSync(t1);

      final hashPath = await encryptionService.hashFilePath(relPath).then((r) => r.getOrElse((_) => throw Exception()));

      final manifestDir = Directory(p.join(tempVaultDir.path, '.prism'))..createSync();
      final manifestFile = File(p.join(manifestDir.path, 'sync_manifest.json'));
      final contentAHash = await calculateContentHash('Content A');
      final r1 = DateTime.now().subtract(const Duration(hours: 2));
      final manifestPayload = {
        'version': 1,
        'files': {
          relPath: {
            'fileHash': contentAHash,
            'lastSyncedModifiedTime': t1.millisecondsSinceEpoch,
            'googleDriveFileId': '$prefix$hashPath',
            'remoteModifiedTime': r1.millisecondsSinceEpoch,
          }
        }
      };
      manifestFile.writeAsStringSync(jsonEncode(manifestPayload));

      // 3. Upload modified content to Drive with a newer modified time r2
      final contentBBytes = utf8.encode('Content B');
      final encryptedB = await packAndEncrypt(relPath, contentBBytes, derivedKey, encryptionService);
      mockDriveService.files['$prefix$hashPath'] = encryptedB;
      final r2 = DateTime.now();
      mockDriveService.modifiedTimes['$prefix$hashPath'] = r2;

      // 4. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));
      expect(result.downloaded, equals(1));
      expect(result.uploaded, equals(0));

      // 5. Verify local file was updated
      expect(localFile.readAsStringSync(), equals('Content B'));

      // 6. Verify manifest is updated
      final updatedManifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final manifestFiles = updatedManifest['files'] as Map<String, dynamic>;
      expect(manifestFiles[relPath]['remoteModifiedTime'], equals(r2.millisecondsSinceEpoch));
    });
  });

  group('TwoWaySyncService - Cycle 5: Conflict Resolution', () {
    Future<Uint8List> packAndEncrypt(String relPath, List<int> fileBytes, SecretKey key, SyncEncryptionService encryptionService) async {
      final pathBytes = utf8.encode(relPath);
      final payload = Uint8List(4 + pathBytes.length + fileBytes.length);
      payload.buffer.asByteData().setUint32(0, pathBytes.length, Endian.big);
      payload.setRange(4, 4 + pathBytes.length, pathBytes);
      payload.setRange(4 + pathBytes.length, payload.length, fileBytes);
      final encryptResult = await encryptionService.encryptBytes(bytes: payload, key: key);
      return encryptResult.getOrElse((_) => throw Exception('Encrypt failed'));
    }

    test('runSync detects conflict, keeps local modified file, saves remote content as conflict copy, and updates SQLite notes index', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);
      
      // Keep databaseProvider alive during the test
      // ignore: unused_local_variable
      final dbSub = container.listen(databaseProvider, (_, _) {});
      final db = await container.read(databaseProvider.future);

      // 1. Setup sync configuration
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      final derivedKeyResult = await encryptionService.deriveKey(passphrase: passphrase, salt: salt);
      final derivedKey = derivedKeyResult.getOrElse((_) => throw Exception('Failed to derive key'));

      // 2. Pre-populate SQLite with the original note record
      const noteId = 'orig_id_123';
      final relPath = 'note_conflict.md';
      final localFilePath = p.join(tempVaultDir.path, relPath);

      await db.insert('notes', {
        'id': noteId,
        'title': 'Note Conflict',
        'file_path': localFilePath,
        'word_count': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_ghost': 0,
      });

      // 3. Create original local file and its manifest entry
      final localFile = File(localFilePath);
      localFile.writeAsStringSync('Content A');
      final t1 = DateTime.now().subtract(const Duration(hours: 2));
      localFile.setLastModifiedSync(t1);

      final hashPath = await encryptionService.hashFilePath(relPath).then((r) => r.getOrElse((_) => throw Exception()));

      final manifestDir = Directory(p.join(tempVaultDir.path, '.prism'))..createSync();
      final manifestFile = File(p.join(manifestDir.path, 'sync_manifest.json'));

      final r1 = DateTime.now().subtract(const Duration(hours: 2));
      final manifestPayload = {
        'version': 1,
        'files': {
          relPath: {
            'fileHash': await calculateContentHash('Content A'),
            'lastSyncedModifiedTime': t1.millisecondsSinceEpoch,
            'googleDriveFileId': '$prefix$hashPath',
            'remoteModifiedTime': r1.millisecondsSinceEpoch,
          }
        }
      };
      manifestFile.writeAsStringSync(jsonEncode(manifestPayload));

      // 4. Edit local file locally -> content B at time t2
      localFile.writeAsStringSync('Content B');
      final t2 = DateTime.now();
      localFile.setLastModifiedSync(t2);

      // 5. Upload modified content C to Drive with newer modification time r2
      final contentCBytes = utf8.encode('Content C');
      final encryptedC = await packAndEncrypt('noteC.md', contentCBytes, derivedKey, encryptionService);
      mockDriveService.files['$prefix$hashPath'] = encryptedC;
      final r2 = DateTime.now();
      mockDriveService.modifiedTimes['$prefix$hashPath'] = r2;

      // 6. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));
      expect(result.conflictsResolved, equals(1));
      expect(result.uploaded, equals(0));
      expect(result.downloaded, equals(0));

      // 7. Verify original file content is untouched (remains Content B)
      expect(localFile.readAsStringSync(), equals('Content B'));

      // 8. Verify conflict copy file exists on disk with content C
      final tempFiles = tempVaultDir.listSync();
      File? conflictFile;
      for (final f in tempFiles) {
        if (f is File && f.path.contains(' (Conflict) - ')) {
          conflictFile = f;
          break;
        }
      }
      expect(conflictFile, isNotNull);
      expect(conflictFile!.readAsStringSync(), equals('Content C'));

      // 9. Verify conflict note is indexed in SQLite with is_conflicted = 1 and original_note_id
      final conflictedRows = await db.query('notes', where: 'is_conflicted = 1');
      expect(conflictedRows.length, equals(1));
      expect(conflictedRows.first['original_note_id'], equals(noteId));
      expect(conflictedRows.first['file_path'], equals(conflictFile.path));
    });
  });

  group('TwoWaySyncService - Cycle 6: Deletions', () {
    test('runSync propagates local deletions to Google Drive and prunes manifest', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Setup sync configuration
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      // 2. Create manifest entry and drive file representing a previously synced file
      final relPath = 'note_to_delete.md';
      final hashPath = await encryptionService.hashFilePath(relPath).then((r) => r.getOrElse((_) => throw Exception()));

      final manifestDir = Directory(p.join(tempVaultDir.path, '.prism'))..createSync();
      final manifestFile = File(p.join(manifestDir.path, 'sync_manifest.json'));

      final t1 = DateTime.now().subtract(const Duration(hours: 1));
      final r1 = DateTime.now().subtract(const Duration(hours: 1));
      final contentHash = await calculateContentHash('Some content');

      // The file is on drive
      mockDriveService.files['$prefix$hashPath'] = utf8.encode('Encrypted content');
      mockDriveService.modifiedTimes['$prefix$hashPath'] = r1;

      // The manifest has the entry
      final manifestPayload = {
        'version': 1,
        'files': {
          relPath: {
            'fileHash': contentHash,
            'lastSyncedModifiedTime': t1.millisecondsSinceEpoch,
            'googleDriveFileId': '$prefix$hashPath',
            'remoteModifiedTime': r1.millisecondsSinceEpoch,
          }
        }
      };
      manifestFile.writeAsStringSync(jsonEncode(manifestPayload));

      // Note: The local file is NOT created on disk, simulating a local deletion!

      // 3. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));
      expect(result.deletedRemote, equals(1));
      expect(result.uploaded, equals(0));
      expect(result.downloaded, equals(0));

      // 4. Verify the remote file was deleted
      expect(mockDriveService.files.containsKey('$prefix$hashPath'), isFalse);

      // 5. Verify the manifest entry was pruned
      final updatedManifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final manifestFiles = updatedManifest['files'] as Map<String, dynamic>;
      expect(manifestFiles.containsKey(relPath), isFalse);
    });
  });

  group('TwoWaySyncService - .prism/templates/ (hidden template folder)', () {
    test('runSync uploads custom templates stored under .prism/templates/', () async {
      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Configure sync
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      // 2. Create a custom template in the HIDDEN .prism/templates/ folder
      //    (this is where TemplateService writes - see issue #7)
      final hiddenTemplateDir = Directory(p.join(tempVaultDir.path, '.prism', 'templates'))
        ..createSync(recursive: true);
      final hiddenTemplateFile = File(p.join(hiddenTemplateDir.path, 'gratitude.md'));
      hiddenTemplateFile.writeAsStringSync('---\ntitle: "Gratitude"\n---\n\nThree good things...');

      // 3. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      final result = syncResult.getOrElse((_) => throw Exception('Sync failed'));

      // 4. The hidden template should have been uploaded.
      final derivedKey = (await encryptionService.deriveKey(
        passphrase: passphrase,
        salt: salt,
      )).getOrElse((_) => throw Exception('deriveKey failed'));

      final relPath = '.prism/templates/gratitude.md';
      final pathHash = (await encryptionService.hashFilePath(relPath))
          .getOrElse((_) => throw Exception('hashFilePath failed'));
      expect(mockDriveService.files.containsKey('$prefix$pathHash'), isTrue,
          reason: 'hidden .prism/templates/ file should be synced to Drive');

      // 5. Decrypt and confirm the content round-trips.
      final encryptedBytes = mockDriveService.files['$prefix$pathHash']!;
      final decryptedBytes = (await encryptionService.decryptBytes(
        encryptedBytes: encryptedBytes,
        key: derivedKey,
      )).getOrElse((_) => throw Exception('decrypt failed'));

      final pathLen = decryptedBytes.buffer.asByteData().getUint32(0, Endian.big);
      final decodedPath = utf8.decode(decryptedBytes.sublist(4, 4 + pathLen));
      final fileContentBytes = decryptedBytes.sublist(4 + pathLen);
      expect(decodedPath, equals(relPath));
      expect(utf8.decode(fileContentBytes), contains('Three good things'));

      // uploaded count should include this one file
      expect(result.uploaded, greaterThanOrEqualTo(1));
    });
  });

  group('TwoWaySyncService - Global Selective Sync', () {
    test('runSync returns Left(SyncConfigurationFailure) if vault is not enabled for sync', () async {
      final vaultName = p.basename(tempVaultDir.path);

      // Explicitly disable sync for this vault
      await container.read(syncedVaultsProvider.notifier).disableSync(vaultName);

      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // Setup sync configuration (simulate global configuration)
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      final result = await syncService.runSync();
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Should be Left'));
      expect(failure, isA<SyncConfigurationFailure>());
      expect(failure.message, contains('Sync is not enabled for this vault'));
    });

    test('runSync prefixes remote filenames with hash(vaultName)', () async {
      final vaultName = p.basename(tempVaultDir.path);

      final syncService = container.read(twoWaySyncServiceProvider);
      final encryptionService = container.read(syncEncryptionServiceProvider);

      // 1. Setup sync configuration
      const passphrase = 'password123';
      final salt = encryptionService.generateSalt();
      mockDriveService.files['sync_salt.json'] = utf8.encode(jsonEncode({'salt': base64Encode(salt)}));
      await mockSecureStorage.write(key: 'sync_passphrase', value: passphrase);

      // 2. Enable sync for the vault
      await container.read(syncedVaultsProvider.notifier).enableSync(vaultName);

      // 3. Create a local note
      final noteFile = File(p.join(tempVaultDir.path, 'note1.md'));
      noteFile.writeAsStringSync('Hello World');

      // 4. Run sync
      final syncResult = await syncService.runSync();
      expect(syncResult.isRight(), isTrue);

      // 5. Verify the file on mock Google Drive is named: hash(vaultName) + "_" + hash(relativePath)
      final vaultHash = (await encryptionService.hashVaultName(vaultName)).getOrElse((_) => throw Exception());
      final pathHash = (await encryptionService.hashFilePath('note1.md')).getOrElse((_) => throw Exception());
      final expectedRemoteName = '${vaultHash}_$pathHash';

      expect(mockDriveService.files.containsKey(expectedRemoteName), isTrue);
    });
  });
}

Future<String> calculateContentHash(String content) async {
  final hash = await Sha256().hash(utf8.encode(content));
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
