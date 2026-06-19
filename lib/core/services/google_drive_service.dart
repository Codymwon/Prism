import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

sealed class GoogleDriveFailure {
  final String message;
  const GoogleDriveFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class GoogleDriveAuthenticationFailure extends GoogleDriveFailure {
  const GoogleDriveAuthenticationFailure(super.message);
}

class GoogleDriveConnectionFailure extends GoogleDriveFailure {
  const GoogleDriveConnectionFailure(super.message);
}

class GoogleDriveFileNotFoundFailure extends GoogleDriveFailure {
  const GoogleDriveFileNotFoundFailure(super.message);
}

class GoogleDriveUnknownFailure extends GoogleDriveFailure {
  const GoogleDriveUnknownFailure(super.message);
}

/// A custom HTTP client that injects authorization headers from Google Sign-In.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleAuthClient(this._headers, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;

  GoogleDriveService({
    GoogleSignIn? googleSignIn,
    drive.DriveApi? driveApi,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveAppdataScope],
            ),
        _driveApi = driveApi;

  bool get isSignedIn => _driveApi != null;

  Future<Either<GoogleDriveFailure, Unit>> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return const Left(GoogleDriveAuthenticationFailure('Silent sign-in failed: No user authenticated.'));
      }
      await _initDriveApi(account);
      return const Right(unit);
    } catch (e) {
      return Left(GoogleDriveAuthenticationFailure('Silent sign-in failed: $e'));
    }
  }

  Future<void> _initDriveApi(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    final client = GoogleAuthClient(headers);
    _driveApi = drive.DriveApi(client);
  }

  Future<Either<GoogleDriveFailure, Unit>> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const Left(GoogleDriveAuthenticationFailure('Sign-in cancelled or failed.'));
      }
      await _initDriveApi(account);
      return const Right(unit);
    } catch (e) {
      return Left(GoogleDriveAuthenticationFailure('Sign-in failed: $e'));
    }
  }

  Future<Either<GoogleDriveFailure, Unit>> signOut() async {
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
      return const Right(unit);
    } catch (e) {
      return Left(GoogleDriveAuthenticationFailure('Sign-out failed: $e'));
    }
  }

  Future<Either<GoogleDriveFailure, List<drive.File>>> listFiles() async {
    if (_driveApi == null) {
      return const Left(GoogleDriveAuthenticationFailure('Not authenticated.'));
    }
    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        $fields: 'files(id, name, mimeType, modifiedTime, size)',
      );
      final files = fileList.files ?? <drive.File>[];
      return Right(files);
    } catch (e) {
      return Left(GoogleDriveUnknownFailure('Failed to list files: $e'));
    }
  }

  Future<Either<GoogleDriveFailure, drive.File>> uploadFile(
    String name,
    List<int> bytes, {
    String? mimeType,
  }) async {
    if (_driveApi == null) {
      return const Left(GoogleDriveAuthenticationFailure('Not authenticated.'));
    }
    try {
      final file = drive.File()
        ..name = name
        ..parents = ['appDataFolder'];

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: mimeType ?? 'application/octet-stream',
      );

      final uploaded = await _driveApi!.files.create(
        file,
        uploadMedia: media,
      );
      return Right(uploaded);
    } catch (e) {
      return Left(GoogleDriveUnknownFailure('Failed to upload file: $e'));
    }
  }

  Future<Either<GoogleDriveFailure, Uint8List>> downloadFile(String fileId) async {
    if (_driveApi == null) {
      return const Left(GoogleDriveAuthenticationFailure('Not authenticated.'));
    }
    try {
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (media is! drive.Media) {
        return const Left(GoogleDriveUnknownFailure('Downloaded content is not media.'));
      }
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return Right(Uint8List.fromList(bytes));
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return Left(GoogleDriveFileNotFoundFailure('File not found: $fileId'));
      }
      return Left(GoogleDriveUnknownFailure('Failed to download file: $e'));
    } catch (e) {
      return Left(GoogleDriveUnknownFailure('Failed to download file: $e'));
    }
  }

  Future<Either<GoogleDriveFailure, Unit>> deleteFile(String fileId) async {
    if (_driveApi == null) {
      return const Left(GoogleDriveAuthenticationFailure('Not authenticated.'));
    }
    try {
      await _driveApi!.files.delete(fileId);
      return const Right(unit);
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return Left(GoogleDriveFileNotFoundFailure('File not found: $fileId'));
      }
      return Left(GoogleDriveUnknownFailure('Failed to delete file: $e'));
    } catch (e) {
      return Left(GoogleDriveUnknownFailure('Failed to delete file: $e'));
    }
  }

  Future<Either<GoogleDriveFailure, drive.File>> updateFile(
    String fileId,
    List<int> bytes, {
    String? mimeType,
  }) async {
    if (_driveApi == null) {
      return const Left(GoogleDriveAuthenticationFailure('Not authenticated.'));
    }
    try {
      final file = drive.File();
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: mimeType ?? 'application/octet-stream',
      );
      final updated = await _driveApi!.files.update(
        file,
        fileId,
        uploadMedia: media,
      );
      return Right(updated);
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return Left(GoogleDriveFileNotFoundFailure('File not found: $fileId'));
      }
      return Left(GoogleDriveUnknownFailure('Failed to update file: $e'));
    } catch (e) {
      return Left(GoogleDriveUnknownFailure('Failed to update file: $e'));
    }
  }
}
