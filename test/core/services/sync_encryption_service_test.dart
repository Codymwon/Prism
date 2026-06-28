import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/core/services/sync_encryption_service.dart';

void main() {
  late SyncEncryptionService service;

  setUp(() {
    service = SyncEncryptionService();
  });

  group('SyncEncryptionService - Salt Generation', () {
    test('generateSalt returns a cryptographically secure 16-byte random salt', () {
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();

      expect(salt1.length, equals(16));
      expect(salt2.length, equals(16));
      expect(salt1, isNot(equals(salt2))); // Two calls should produce different random salts
    });
  });

  group('SyncEncryptionService - Key Derivation', () {
    test('deriveKey derives the same key for same inputs, different for different inputs', () async {
      const passphrase = 'test-password';
      final salt = service.generateSalt();

      final result1 = await service.deriveKey(passphrase: passphrase, salt: salt);
      final result2 = await service.deriveKey(passphrase: passphrase, salt: salt);

      expect(result1.isRight(), isTrue);
      expect(result2.isRight(), isTrue);

      final key1 = result1.getOrElse((_) => throw Exception('Failed to get key'));
      final key2 = result2.getOrElse((_) => throw Exception('Failed to get key'));

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, equals(bytes2));

      // Different password
      final resultDiffPass = await service.deriveKey(passphrase: 'other-password', salt: salt);
      final keyDiffPass = resultDiffPass.getOrElse((_) => throw Exception('Failed'));
      final bytesDiffPass = await keyDiffPass.extractBytes();
      expect(bytes1, isNot(equals(bytesDiffPass)));

      // Different salt
      final salt2 = service.generateSalt();
      final resultDiffSalt = await service.deriveKey(passphrase: passphrase, salt: salt2);
      final keyDiffSalt = resultDiffSalt.getOrElse((_) => throw Exception('Failed'));
      final bytesDiffSalt = await keyDiffSalt.extractBytes();
      expect(bytes1, isNot(equals(bytesDiffSalt)));
    });
  });

  group('SyncEncryptionService - Encryption', () {
    test('encryptBytes returns encrypted bytes with unique IVs and correct length', () async {
      const passphrase = 'test-password';
      final salt = service.generateSalt();
      final keyResult = await service.deriveKey(passphrase: passphrase, salt: salt);
      final key = keyResult.getOrElse((_) => throw Exception('Failed to get key'));

      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      final encryptResult1 = await service.encryptBytes(bytes: plaintext, key: key);
      final encryptResult2 = await service.encryptBytes(bytes: plaintext, key: key);

      expect(encryptResult1.isRight(), isTrue);
      expect(encryptResult2.isRight(), isTrue);

      final ciphertext1 = encryptResult1.getOrElse((_) => throw Exception('Failed'));
      final ciphertext2 = encryptResult2.getOrElse((_) => throw Exception('Failed'));

      // Output size: 12 (nonce) + 8 (plaintext) + 16 (mac) = 36
      expect(ciphertext1.length, equals(12 + plaintext.length + 16));
      expect(ciphertext2.length, equals(12 + plaintext.length + 16));

      // Unique IVs mean different ciphertexts
      expect(ciphertext1, isNot(equals(ciphertext2)));
    });
  });

  group('SyncEncryptionService - Decryption', () {
    test('decryptBytes successfully decrypts valid ciphertext with correct key', () async {
      const passphrase = 'test-password';
      final salt = service.generateSalt();
      final keyResult = await service.deriveKey(passphrase: passphrase, salt: salt);
      final key = keyResult.getOrElse((_) => throw Exception('Failed to get key'));

      final plaintext = Uint8List.fromList([10, 20, 30, 40, 50]);

      final encryptResult = await service.encryptBytes(bytes: plaintext, key: key);
      final ciphertext = encryptResult.getOrElse((_) => throw Exception('Failed to encrypt'));

      final decryptResult = await service.decryptBytes(encryptedBytes: ciphertext, key: key);
      expect(decryptResult.isRight(), isTrue);

      final decryptedBytes = decryptResult.getOrElse((_) => throw Exception('Failed to decrypt'));
      expect(decryptedBytes, equals(plaintext));
    });

    test('decryptBytes returns Left(DecryptionFailure) with wrong key', () async {
      const passphrase = 'test-password';
      final salt = service.generateSalt();
      final keyResult = await service.deriveKey(passphrase: passphrase, salt: salt);
      final key = keyResult.getOrElse((_) => throw Exception('Failed to get key'));

      final wrongKeyResult = await service.deriveKey(passphrase: 'wrong-password', salt: salt);
      final wrongKey = wrongKeyResult.getOrElse((_) => throw Exception('Failed to get wrong key'));

      final plaintext = Uint8List.fromList([10, 20, 30, 40, 50]);
      final encryptResult = await service.encryptBytes(bytes: plaintext, key: key);
      final ciphertext = encryptResult.getOrElse((_) => throw Exception('Failed to encrypt'));

      final decryptResult = await service.decryptBytes(encryptedBytes: ciphertext, key: wrongKey);
      expect(decryptResult.isLeft(), isTrue);

      final failure = decryptResult.swap().getOrElse((_) => throw Exception('Should be Left'));
      expect(failure, isA<DecryptionFailure>());
    });

    test('decryptBytes returns Left(DecryptionFailure) with corrupted bytes', () async {
      const passphrase = 'test-password';
      final salt = service.generateSalt();
      final keyResult = await service.deriveKey(passphrase: passphrase, salt: salt);
      final key = keyResult.getOrElse((_) => throw Exception('Failed to get key'));

      final plaintext = Uint8List.fromList([10, 20, 30, 40, 50]);
      final encryptResult = await service.encryptBytes(bytes: plaintext, key: key);
      final ciphertext = encryptResult.getOrElse((_) => throw Exception('Failed to encrypt'));

      // Corrupt a byte in the ciphertext
      final corruptedCiphertext = Uint8List.fromList(ciphertext);
      corruptedCiphertext[corruptedCiphertext.length - 1] ^= 0xFF;

      final decryptResult = await service.decryptBytes(encryptedBytes: corruptedCiphertext, key: key);
      expect(decryptResult.isLeft(), isTrue);

      final failure = decryptResult.swap().getOrElse((_) => throw Exception('Should be Left'));
      expect(failure, isA<DecryptionFailure>());
    });
  });

  group('SyncEncryptionService - Path Hashing', () {
    test('hashFilePath hashes relative path to lowercase SHA-256 hex string', () async {
      const path1 = 'notes/hello-world.md';
      const path2 = 'notes/hello-world.md';
      const path3 = 'notes/other-note.md';

      final hashResult1 = await service.hashFilePath(path1);
      final hashResult2 = await service.hashFilePath(path2);
      final hashResult3 = await service.hashFilePath(path3);

      expect(hashResult1.isRight(), isTrue);
      expect(hashResult2.isRight(), isTrue);
      expect(hashResult3.isRight(), isTrue);

      final hash1 = hashResult1.getOrElse((_) => throw Exception('Failed'));
      final hash2 = hashResult2.getOrElse((_) => throw Exception('Failed'));
      final hash3 = hashResult3.getOrElse((_) => throw Exception('Failed'));

      // SHA-256 hex string is 64 characters
      expect(hash1.length, equals(64));
      expect(hash2.length, equals(64));
      expect(hash3.length, equals(64));

      // Same paths have same hash
      expect(hash1, equals(hash2));

      // Different paths have different hashes
      expect(hash1, isNot(equals(hash3)));

      // Lowercase check
      expect(hash1, equals(hash1.toLowerCase()));
      // Ensure only valid hex characters [0-9a-f]
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash1), isTrue);
    });
  });

  group('SyncEncryptionService - Riverpod Provider', () {
    test('syncEncryptionServiceProvider resolves SyncEncryptionService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final resolvedService = container.read(syncEncryptionServiceProvider);
      expect(resolvedService, isA<SyncEncryptionService>());
    });
  });

  group('SyncEncryptionService - Vault Name Hashing', () {
    test('hashVaultName hashes vault name to lowercase SHA-256 hex string', () async {
      const vault1 = 'Work Vault';
      const vault2 = 'Work Vault';
      const vault3 = 'Personal';

      final hashResult1 = await service.hashVaultName(vault1);
      final hashResult2 = await service.hashVaultName(vault2);
      final hashResult3 = await service.hashVaultName(vault3);

      expect(hashResult1.isRight(), isTrue);
      expect(hashResult2.isRight(), isTrue);
      expect(hashResult3.isRight(), isTrue);

      final hash1 = hashResult1.getOrElse((_) => throw Exception('Failed'));
      final hash2 = hashResult2.getOrElse((_) => throw Exception('Failed'));
      final hash3 = hashResult3.getOrElse((_) => throw Exception('Failed'));

      expect(hash1.length, equals(64));
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1, equals(hash1.toLowerCase()));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash1), isTrue);
    });
  });
}
