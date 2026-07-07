import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import '../database/vault_providers.dart';
import '../database/database_providers.dart';
import '../utils/utils.dart' as utils;
import 'note_ingestion_service.dart';
import 'google_drive_service.dart';
import 'sync_encryption_service.dart';
import 'analytics_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

sealed class SyncFailure {
  final String message;
  const SyncFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class SyncConfigurationFailure extends SyncFailure {
  const SyncConfigurationFailure(super.message);
}

class SyncFileSystemFailure extends SyncFailure {
  const SyncFileSystemFailure(super.message);
}

class SyncEncryptionFailure extends SyncFailure {
  const SyncEncryptionFailure(super.message);
}

class SyncNetworkFailure extends SyncFailure {
  const SyncNetworkFailure(super.message);
}

class SyncDatabaseFailure extends SyncFailure {
  const SyncDatabaseFailure(super.message);
}

class SyncUnknownFailure extends SyncFailure {
  const SyncUnknownFailure(super.message);
}

class SyncResult {
  final int uploaded;
  final int downloaded;
  final int deletedLocal;
  final int deletedRemote;
  final int conflictsResolved;

  const SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.deletedLocal = 0,
    this.deletedRemote = 0,
    this.conflictsResolved = 0,
  });
}

abstract class TwoWaySyncService {
  Future<Either<SyncFailure, Unit>> configureSync({required String passphrase});
  Future<Either<SyncFailure, SyncResult>> runSync();
  Future<bool> isSyncConfigured();
  Future<Either<SyncFailure, Unit>> deleteVaultCloudData(String vaultName);
}

final twoWaySyncServiceProvider = Provider<TwoWaySyncService>((ref) {
  return TwoWaySyncServiceImpl(ref);
});

class TwoWaySyncServiceImpl implements TwoWaySyncService {
  final Ref _ref;

  TwoWaySyncServiceImpl(this._ref);

  GoogleDriveService get _driveService => _ref.read(googleDriveServiceProvider);
  SyncEncryptionService get _encryptionService => _ref.read(syncEncryptionServiceProvider);
  FlutterSecureStorage get _secureStorage => _ref.read(secureStorageProvider);

  @override
  Future<bool> isSyncConfigured() async {
    return await _secureStorage.containsKey(key: 'sync_passphrase');
  }

  @override
  Future<Either<SyncFailure, Unit>> configureSync({required String passphrase}) async {
    try {
      final salt = _encryptionService.generateSalt();
      final saltBase64 = base64Encode(salt);
      final saltPayload = jsonEncode({'salt': saltBase64});

      final uploadResult = await _driveService.uploadFile(
        'sync_salt.json',
        utf8.encode(saltPayload),
        mimeType: 'application/json',
      );

      return await uploadResult.fold(
        (failure) async => Left(SyncConfigurationFailure('Failed to upload salt: ${failure.message}')),
        (file) async {
          await _secureStorage.write(key: 'sync_passphrase', value: passphrase);
          return const Right(unit);
        },
      );
    } catch (e) {
      return Left(SyncConfigurationFailure('Error configuring sync: $e'));
    }
  }

  Future<String> _calculateFileHash(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<List<File>> _scanLocalFiles(String vaultPath) async {
    final files = <File>[];
    final rootDir = Directory(vaultPath);
    if (!await rootDir.exists()) return files;

    await for (final entity in rootDir.list(recursive: false)) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name.contains(' (Conflict) - ')) continue;
        if (name.endsWith('.md')) {
          files.add(entity);
        } else if (name == '.prism-metadata.json') {
          files.add(entity);
        }
      }
    }

    final attachDir = Directory(p.join(vaultPath, 'attachments'));
    if (await attachDir.exists()) {
      await for (final entity in attachDir.list(recursive: true)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.contains(' (Conflict) - ')) continue;
          files.add(entity);
        }
      }
    }

    final templateDir = Directory(p.join(vaultPath, 'templates'));
    if (await templateDir.exists()) {
      await for (final entity in templateDir.list(recursive: true)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.contains(' (Conflict) - ')) continue;
          files.add(entity);
        }
      }
    }

    // Custom templates written by TemplateService live in the hidden
    // .prism/templates/ folder (see issue #7). Sync them so user templates
    // round-trip across devices, mirroring the non-hidden templates/ block.
    final hiddenTemplateDir = Directory(p.join(vaultPath, '.prism', 'templates'));
    if (await hiddenTemplateDir.exists()) {
      await for (final entity in hiddenTemplateDir.list(recursive: true)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.contains(' (Conflict) - ')) continue;
          files.add(entity);
        }
      }
    }

    return files;
  }

  String _getRelativePath(String filePath, String vaultPath) {
    return p.relative(filePath, from: vaultPath).replaceAll('\\', '/');
  }

  @override
  Future<Either<SyncFailure, SyncResult>> runSync() async {
    final result = await _runSyncInternal();
    result.fold(
      (failure) {
        AnalyticsService.logError(Exception(failure.message), null, fatal: false);
        AnalyticsService.logEvent('sync_run', parameters: {
          'status': 'failure',
          'error': failure.runtimeType.toString(),
        });
      },
      (success) {
        AnalyticsService.logEvent('sync_run', parameters: {
          'status': 'success',
          'uploaded': success.uploaded,
          'downloaded': success.downloaded,
        });
      },
    );
    return result;
  }

  Future<Either<SyncFailure, SyncResult>> _runSyncInternal() async {
    try {
      final vaultPath = await _ref.read(activeVaultPathProvider.future);
      if (vaultPath.isEmpty) {
        return Left(SyncFileSystemFailure('Active vault path is empty'));
      }

      final activeVaultName = await _ref.read(activeVaultNameProvider.future);
      if (activeVaultName.isEmpty) {
        return Left(SyncFileSystemFailure('Active vault name is empty'));
      }

      final syncedVaults = await _ref.read(syncedVaultsProvider.future);
      if (!syncedVaults.contains(activeVaultName)) {
        return Left(SyncConfigurationFailure('Sync is not enabled for this vault'));
      }

      final vaultHashResult = await _encryptionService.hashVaultName(activeVaultName);
      if (vaultHashResult.isLeft()) {
        return Left(SyncEncryptionFailure('Failed to hash vault name'));
      }
      final vaultHash = vaultHashResult.getOrElse((_) => throw Exception());
      final prefix = '${vaultHash}_';

      final passphrase = await _secureStorage.read(key: 'sync_passphrase');
      if (passphrase == null) {
        return Left(SyncConfigurationFailure('Sync passphrase is not configured'));
      }

      // 1. Get Google Drive file list
      final remoteFilesResult = await _driveService.listFiles();
      if (remoteFilesResult.isLeft()) {
        return Left(SyncNetworkFailure('Failed to list remote files'));
      }
      final remoteFiles = remoteFilesResult.getOrElse((_) => []);
      final remoteFilesMap = <String, String>{};
      for (final f in remoteFiles) {
        if (f.name == 'sync_salt.json') {
          remoteFilesMap['sync_salt.json'] = f.id!;
          continue;
        }
        if (f.name!.startsWith(prefix)) {
          final pathHash = f.name!.substring(prefix.length);
          remoteFilesMap[pathHash] = f.id!;
        }
      }

      // 2. Download and parse salt
      final saltFileId = remoteFilesMap['sync_salt.json'];
      if (saltFileId == null) {
        return Left(SyncConfigurationFailure('sync_salt.json not found on Google Drive'));
      }

      final downloadSaltResult = await _driveService.downloadFile(saltFileId);
      if (downloadSaltResult.isLeft()) {
        return Left(SyncNetworkFailure('Failed to download salt file'));
      }
      final saltBytes = downloadSaltResult.getOrElse((_) => Uint8List(0));
      final saltData = jsonDecode(utf8.decode(saltBytes)) as Map<String, dynamic>;
      final saltBase64 = saltData['salt'] as String;
      final salt = base64Decode(saltBase64);

      // 3. Derive key
      final keyResult = await _encryptionService.deriveKey(passphrase: passphrase, salt: salt);
      if (keyResult.isLeft()) {
        return Left(SyncEncryptionFailure('Failed to derive encryption key'));
      }
      final key = keyResult.getOrElse((_) => throw Exception());

      // 4. Load or create local manifest
      final manifestDir = Directory(p.join(vaultPath, '.prism'));
      if (!await manifestDir.exists()) {
        await manifestDir.create(recursive: true);
      }
      final manifestFile = File(p.join(manifestDir.path, 'sync_manifest.json'));
      Map<String, dynamic> manifestData = {'version': 1, 'files': <String, dynamic>{}};
      if (await manifestFile.exists()) {
        try {
          manifestData = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
        } catch (_) {}
      }
      final filesRaw = manifestData['files'];
      final Map<String, dynamic> filesMap = filesRaw is Map ? Map<String, dynamic>.from(filesRaw) : {};
      final manifestFiles = filesMap.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)));

      // 5. Build manifest hash-to-path mapping
      final Map<String, String> manifestHashToPath = {};
      for (final relPath in manifestFiles.keys) {
        final hash = (await _encryptionService.hashFilePath(relPath)).getOrElse((_) => throw Exception());
        manifestHashToPath[hash] = relPath;
      }

      int deletedRemoteCount = 0;
      final List<String> pathsToPrune = [];
      final Set<String> deletedRemoteFileIds = {};

      for (final relPath in manifestFiles.keys) {
        final localFilePath = p.normalize(p.join(vaultPath, relPath));
        final localFile = File(localFilePath);
        if (!await localFile.exists()) {
          // File was deleted locally!
          final entry = manifestFiles[relPath]!;
          final driveFileId = entry['googleDriveFileId'] as String?;
          if (driveFileId != null) {
            await _driveService.deleteFile(driveFileId);
            deletedRemoteFileIds.add(driveFileId);
          }
          pathsToPrune.add(relPath);
          deletedRemoteCount++;
        }
      }

      // Prune deleted files from manifest files map
      for (final relPath in pathsToPrune) {
        manifestFiles.remove(relPath);
        final hash = (await _encryptionService.hashFilePath(relPath)).getOrElse((_) => '');
        manifestHashToPath.remove(hash);
      }

      int downloadedCount = 0;
      int conflictsResolvedCount = 0;

      // 6. Download remote-only files or remotely modified files
      for (final remoteFile in remoteFiles) {
        if (remoteFile.name == 'sync_salt.json') continue;
        if (!remoteFile.name!.startsWith(prefix)) continue; // Skip other vaults
        if (deletedRemoteFileIds.contains(remoteFile.id)) continue;

        final pathHash = remoteFile.name!.substring(prefix.length);
        final localRelPath = manifestHashToPath[pathHash];
        final currentRemoteMod = remoteFile.modifiedTime?.millisecondsSinceEpoch ?? 0;

        if (localRelPath == null) {
          // Download new remote file
          final downloadResult = await _driveService.downloadFile(remoteFile.id!);
          if (downloadResult.isLeft()) {
            return Left(SyncNetworkFailure('Failed to download new file: $pathHash'));
          }
          final encryptedBytes = downloadResult.getOrElse((_) => Uint8List(0));

          // Decrypt
          final decryptResult = await _encryptionService.decryptBytes(encryptedBytes: encryptedBytes, key: key);
          if (decryptResult.isLeft()) {
            return Left(SyncEncryptionFailure('Failed to decrypt new file: $pathHash'));
          }
          final decryptedBytes = decryptResult.getOrElse((_) => Uint8List(0));

          // Decode: [4-byte path length] + [UTF-8 path] + [file content]
          final pathLen = decryptedBytes.buffer.asByteData().getUint32(0, Endian.big);
          final relPath = utf8.decode(decryptedBytes.sublist(4, 4 + pathLen));
          final fileBytes = decryptedBytes.sublist(4 + pathLen);

          // Write local file
          final localFilePath = p.normalize(p.join(vaultPath, relPath));
          final localFile = File(localFilePath);
          final parentDir = localFile.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          await localFile.writeAsBytes(fileBytes);

          // Update manifest
          final contentHash = await _calculateFileHash(fileBytes);
          final stat = await localFile.stat();
          manifestFiles[relPath] = {
            'fileHash': contentHash,
            'lastSyncedModifiedTime': stat.modified.millisecondsSinceEpoch,
            'googleDriveFileId': remoteFile.id,
            'remoteModifiedTime': currentRemoteMod,
          };

          // Rebuild mapping
          manifestHashToPath[pathHash] = relPath;
          downloadedCount++;
        } else {
          // Check for remote modification
          final manifestEntry = manifestFiles[localRelPath]!;
          final lastRemoteMod = manifestEntry['remoteModifiedTime'] as int? ?? 0;

          if (currentRemoteMod > lastRemoteMod + 1000) {
            final localFilePath = p.normalize(p.join(vaultPath, localRelPath));
            final localFile = File(localFilePath);
            bool isLocalModified = false;
            String? localContentHash;
            if (await localFile.exists()) {
              final localBytes = await localFile.readAsBytes();
              localContentHash = await _calculateFileHash(localBytes);
              isLocalModified = localContentHash != manifestEntry['fileHash'];
            }

            if (isLocalModified) {
              // ─── Conflict Resolution ───────────────────────────────────────
              // Download remotely modified version to save as conflict copy
              final downloadResult = await _driveService.downloadFile(remoteFile.id!);
              if (downloadResult.isLeft()) {
                return Left(SyncNetworkFailure('Failed to download conflicted file: $pathHash'));
              }
              final encryptedBytes = downloadResult.getOrElse((_) => Uint8List(0));

              // Decrypt
              final decryptResult = await _encryptionService.decryptBytes(encryptedBytes: encryptedBytes, key: key);
              if (decryptResult.isLeft()) {
                return Left(SyncEncryptionFailure('Failed to decrypt conflicted file: $pathHash'));
              }
              final decryptedBytes = decryptResult.getOrElse((_) => Uint8List(0));

              // Decode
              final pathLen = decryptedBytes.buffer.asByteData().getUint32(0, Endian.big);
              final fileBytes = decryptedBytes.sublist(4 + pathLen);

              // Generate conflict copy path
              final uuid = utils.generateId();
              final dir = p.dirname(localRelPath);
              final ext = p.extension(localRelPath);
              final base = p.basenameWithoutExtension(localRelPath);
              final conflictRelPath = p.join(dir, '$base (Conflict) - $uuid$ext').replaceAll('\\', '/');
              final conflictFilePath = p.normalize(p.join(vaultPath, conflictRelPath));

              // Write conflict copy
              final conflictFile = File(conflictFilePath);
              final parentDir = conflictFile.parent;
              if (!await parentDir.exists()) {
                await parentDir.create(recursive: true);
              }
              await conflictFile.writeAsBytes(fileBytes);

              // Mark original file as synced in the manifest so it is not uploaded/modified again
              final stat = await localFile.stat();
              manifestFiles[localRelPath] = {
                'fileHash': localContentHash,
                'lastSyncedModifiedTime': stat.modified.millisecondsSinceEpoch,
                'googleDriveFileId': remoteFile.id,
                'remoteModifiedTime': currentRemoteMod,
              };

              // Special handling for notes: index original and update conflict properties in DB
              if (localRelPath.endsWith('.md')) {
                final db = await _ref.read(databaseProvider.future);
                final originalMaps = await db.query(
                  'notes',
                  columns: ['id'],
                  where: 'file_path = ?',
                  whereArgs: [localFilePath],
                );

                if (originalMaps.isNotEmpty) {
                  final originalNoteId = originalMaps.first['id'] as String;

                  // Trigger syncVault so it indexes the new conflict file
                  await _ref.read(noteIngestionServiceProvider).syncVault(vaultPath);

                  // Retrieve the newly indexed conflict note's ID
                  final conflictMaps = await db.query(
                    'notes',
                    columns: ['id'],
                    where: 'file_path = ?',
                    whereArgs: [conflictFilePath],
                  );

                  if (conflictMaps.isNotEmpty) {
                    final conflictNoteId = conflictMaps.first['id'] as String;

                    // Update DB with is_conflicted = 1 and original_note_id
                    await db.update(
                      'notes',
                      {
                        'is_conflicted': 1,
                        'original_note_id': originalNoteId,
                      },
                      where: 'id = ?',
                      whereArgs: [conflictNoteId],
                    );
                  }
                }
              }

              conflictsResolvedCount++;
            } else {
              // ─── Normal Remote Modification (Overwrite Local) ──────────────
              final downloadResult = await _driveService.downloadFile(remoteFile.id!);
              if (downloadResult.isLeft()) {
                return Left(SyncNetworkFailure('Failed to download modified file: $pathHash'));
              }
              final encryptedBytes = downloadResult.getOrElse((_) => Uint8List(0));

              // Decrypt
              final decryptResult = await _encryptionService.decryptBytes(encryptedBytes: encryptedBytes, key: key);
              if (decryptResult.isLeft()) {
                return Left(SyncEncryptionFailure('Failed to decrypt modified file: $pathHash'));
              }
              final decryptedBytes = decryptResult.getOrElse((_) => Uint8List(0));

              // Decode
              final pathLen = decryptedBytes.buffer.asByteData().getUint32(0, Endian.big);
              final relPath = utf8.decode(decryptedBytes.sublist(4, 4 + pathLen));
              final fileBytes = decryptedBytes.sublist(4 + pathLen);

              // Write local file
              final parentDir = localFile.parent;
              if (!await parentDir.exists()) {
                await parentDir.create(recursive: true);
              }
              await localFile.writeAsBytes(fileBytes);

              // Update manifest
              final contentHash = await _calculateFileHash(fileBytes);
              final stat = await localFile.stat();
              manifestFiles[relPath] = {
                'fileHash': contentHash,
                'lastSyncedModifiedTime': stat.modified.millisecondsSinceEpoch,
                'googleDriveFileId': remoteFile.id,
                'remoteModifiedTime': currentRemoteMod,
              };

              downloadedCount++;
            }
          }
        }
      }

      // 7. Scan local files (includes any newly downloaded files)
      final localFiles = await _scanLocalFiles(vaultPath);

      int uploadedCount = 0;

      for (final file in localFiles) {
        final relPath = _getRelativePath(file.path, vaultPath);
        final fileBytes = await file.readAsBytes();
        final localContentHash = await _calculateFileHash(fileBytes);

        final manifestEntry = manifestFiles[relPath];
        final pathHash = (await _encryptionService.hashFilePath(relPath)).getOrElse((_) => throw Exception());

        // Determine if we need to upload
        bool shouldUpload = false;
        String? googleDriveFileId;

        if (manifestEntry == null) {
          shouldUpload = true;
        } else {
          googleDriveFileId = manifestEntry['googleDriveFileId'] as String?;
          final lastSyncedHash = manifestEntry['fileHash'] as String?;
          if (localContentHash != lastSyncedHash) {
            shouldUpload = true;
          }
        }

        if (shouldUpload) {
          // Pack: [4-byte big-endian path length] + [path] + [file content]
          final pathBytes = utf8.encode(relPath);
          final payload = Uint8List(4 + pathBytes.length + fileBytes.length);
          payload.buffer.asByteData().setUint32(0, pathBytes.length, Endian.big);
          payload.setRange(4, 4 + pathBytes.length, pathBytes);
          payload.setRange(4 + pathBytes.length, payload.length, fileBytes);

          // Encrypt
          final encryptResult = await _encryptionService.encryptBytes(bytes: payload, key: key);
          if (encryptResult.isLeft()) {
            return Left(SyncEncryptionFailure('Failed to encrypt file: $relPath'));
          }
          final encryptedBytes = encryptResult.getOrElse((_) => Uint8List(0));

          // Upload or update
          final existingDriveId = remoteFilesMap[pathHash];
          drive.File uploadedFile;
          final remoteName = '$prefix$pathHash';
          if (existingDriveId != null) {
            final updateResult = await _driveService.updateFile(existingDriveId, encryptedBytes);
            if (updateResult.isLeft()) {
              return Left(SyncNetworkFailure('Failed to update remote file: $relPath'));
            }
            uploadedFile = updateResult.getOrElse((_) => drive.File());
            googleDriveFileId = existingDriveId;
          } else {
            final uploadResult = await _driveService.uploadFile(remoteName, encryptedBytes);
            if (uploadResult.isLeft()) {
              return Left(SyncNetworkFailure('Failed to upload remote file: $relPath'));
            }
            uploadedFile = uploadResult.getOrElse((_) => drive.File());
            googleDriveFileId = uploadedFile.id;
          }

          // Update manifest entry
          final stat = await file.stat();
          final remoteModTime = uploadedFile.modifiedTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
          manifestFiles[relPath] = {
            'fileHash': localContentHash,
            'lastSyncedModifiedTime': stat.modified.millisecondsSinceEpoch,
            'googleDriveFileId': googleDriveFileId,
            'remoteModifiedTime': remoteModTime,
          };
          uploadedCount++;
        }
      }

      // 8. Save manifest
      manifestData['files'] = manifestFiles;
      await manifestFile.writeAsString(const JsonEncoder.withIndent('  ').convert(manifestData));

      return Right(SyncResult(
        uploaded: uploadedCount,
        downloaded: downloadedCount,
        conflictsResolved: conflictsResolvedCount,
        deletedRemote: deletedRemoteCount,
      ));
    } catch (e) {
      return Left(SyncFileSystemFailure('Sync execution error: $e'));
    }
  }

  @override
  Future<Either<SyncFailure, Unit>> deleteVaultCloudData(String vaultName) async {
    try {
      final vaultHashResult = await _encryptionService.hashVaultName(vaultName);
      if (vaultHashResult.isLeft()) {
        return Left(SyncEncryptionFailure('Failed to hash vault name'));
      }
      final vaultHash = vaultHashResult.getOrElse((_) => throw Exception());
      final prefix = '${vaultHash}_';

      final remoteFilesResult = await _driveService.listFiles();
      if (remoteFilesResult.isLeft()) {
        return Left(SyncNetworkFailure('Failed to list remote files'));
      }
      final remoteFiles = remoteFilesResult.getOrElse((_) => []);
      for (final f in remoteFiles) {
        if (f.name != null && f.name!.startsWith(prefix) && f.id != null) {
          final deleteResult = await _driveService.deleteFile(f.id!);
          if (deleteResult.isLeft()) {
            return Left(SyncNetworkFailure('Failed to delete remote file: ${f.name}'));
          }
        }
      }
      return const Right(unit);
    } catch (e) {
      return Left(SyncUnknownFailure('Failed to delete vault cloud data: $e'));
    }
  }
}
