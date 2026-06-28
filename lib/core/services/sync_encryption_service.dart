import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final syncEncryptionServiceProvider = Provider<SyncEncryptionService>((ref) {
  return SyncEncryptionService();
});

sealed class CryptographicFailure {
  final String message;
  const CryptographicFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class KeyDerivationFailure extends CryptographicFailure {
  const KeyDerivationFailure(super.message);
}

class EncryptionFailure extends CryptographicFailure {
  const EncryptionFailure(super.message);
}

class DecryptionFailure extends CryptographicFailure {
  const DecryptionFailure(super.message);
}

class PathHashingFailure extends CryptographicFailure {
  const PathHashingFailure(super.message);
}

class SyncEncryptionService {
  static const int pbkdf2Iterations = 100000;
  static const int pbkdf2KeyLengthBits = 256;

  /// Generates a cryptographically secure random salt (16 bytes)
  Uint8List generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Derives an encryption key from a passphrase and a salt via PBKDF2-HMAC-SHA256
  Future<Either<CryptographicFailure, SecretKey>> deriveKey({
    required String passphrase,
    required List<int> salt,
  }) async {
    try {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: pbkdf2Iterations,
        bits: pbkdf2KeyLengthBits,
      );
      final key = await pbkdf2.deriveKeyFromPassword(
        password: passphrase,
        nonce: salt,
      );
      return Right(key);
    } catch (e) {
      return Left(KeyDerivationFailure('Failed to derive key: $e'));
    }
  }

  final _aesGcm = AesGcm.with256bits();

  /// Encrypts bytes using AES-256-GCM.
  /// Returns a concatenated byte list: [nonce] + [ciphertext] + [mac]
  Future<Either<CryptographicFailure, Uint8List>> encryptBytes({
    required List<int> bytes,
    required SecretKey key,
  }) async {
    try {
      final secretBox = await _aesGcm.encrypt(
        bytes,
        secretKey: key,
      );
      final concatenated = secretBox.concatenation();
      return Right(Uint8List.fromList(concatenated));
    } catch (e) {
      return Left(EncryptionFailure('Encryption failed: $e'));
    }
  }

  /// Decrypts bytes using AES-256-GCM.
  /// Expects a concatenated byte list: [nonce] + [ciphertext] + [mac]
  Future<Either<CryptographicFailure, Uint8List>> decryptBytes({
    required List<int> encryptedBytes,
    required SecretKey key,
  }) async {
    try {
      final secretBox = SecretBox.fromConcatenation(
        encryptedBytes,
        nonceLength: _aesGcm.nonceLength,
        macLength: _aesGcm.macAlgorithm.macLength,
      );
      final decrypted = await _aesGcm.decrypt(
        secretBox,
        secretKey: key,
      );
      return Right(Uint8List.fromList(decrypted));
    } catch (e) {
      return Left(DecryptionFailure('Decryption failed: $e'));
    }
  }

  /// Hashes a relative file path using SHA-256 and returns a lowercase hex string
  Future<Either<CryptographicFailure, String>> hashFilePath(String relativePath) async {
    try {
      final bytes = utf8.encode(relativePath);
      final hash = await Sha256().hash(bytes);
      final hex = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return Right(hex.toLowerCase());
    } catch (e) {
      return Left(PathHashingFailure('Failed to hash path: $e'));
    }
  }

  /// Hashes a vault name using SHA-256 and returns a lowercase hex string
  Future<Either<CryptographicFailure, String>> hashVaultName(String vaultName) async {
    try {
      final bytes = utf8.encode(vaultName);
      final hash = await Sha256().hash(bytes);
      final hex = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return Right(hex.toLowerCase());
    } catch (e) {
      return Left(PathHashingFailure('Failed to hash vault name: $e'));
    }
  }
}
