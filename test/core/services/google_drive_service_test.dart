import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:prism/core/services/google_drive_service.dart';
import 'package:http/http.dart' as http;

class MockGoogleSignIn extends Fake implements GoogleSignIn {
  GoogleSignInAccount? mockAccount;
  bool signInSilentlyCalled = false;
  bool signInCalled = false;
  bool signOutCalled = false;

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    signInSilentlyCalled = true;
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalled = true;
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalled = true;
    return null;
  }

  bool disconnectCalled = false;
  @override
  Future<GoogleSignInAccount?> disconnect() async {
    disconnectCalled = true;
    return null;
  }
}

class MockGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  final Map<String, String> mockHeaders;

  MockGoogleSignInAccount(this.mockHeaders);

  @override
  Future<Map<String, String>> get authHeaders async => mockHeaders;
}

void main() {
  group('GoogleDriveService - Initialization & Silent Sign-In', () {
    test('signInSilently returns Right(unit) on successful silent sign-in and initializes drive client', () async {
      final mockSignIn = MockGoogleSignIn();
      final mockAccount = MockGoogleSignInAccount({'Authorization': 'Bearer test-token'});
      mockSignIn.mockAccount = mockAccount;

      final service = GoogleDriveService(googleSignIn: mockSignIn);
      expect(service.isSignedIn, isFalse);

      final result = await service.signInSilently();
      expect(result.isRight(), isTrue);
      expect(service.isSignedIn, isTrue);
      expect(mockSignIn.signInSilentlyCalled, isTrue);
    });

    test('signInSilently returns Left(GoogleDriveAuthenticationFailure) when silent sign-in fails', () async {
      final mockSignIn = MockGoogleSignIn();
      mockSignIn.mockAccount = null; // Fails to sign in silently

      final service = GoogleDriveService(googleSignIn: mockSignIn);
      expect(service.isSignedIn, isFalse);

      final result = await service.signInSilently();
      expect(result.isLeft(), isTrue);
      expect(service.isSignedIn, isFalse);
      
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });
  });

  group('GoogleDriveService - Explicit Sign-In', () {
    test('signIn returns Right(unit) on successful sign-in and initializes drive client', () async {
      final mockSignIn = MockGoogleSignIn();
      final mockAccount = MockGoogleSignInAccount({'Authorization': 'Bearer test-token'});
      mockSignIn.mockAccount = mockAccount;

      final service = GoogleDriveService(googleSignIn: mockSignIn);
      expect(service.isSignedIn, isFalse);

      final result = await service.signIn();
      expect(result.isRight(), isTrue);
      expect(service.isSignedIn, isTrue);
      expect(mockSignIn.signInCalled, isTrue);
    });

    test('signIn returns Left(GoogleDriveAuthenticationFailure) when sign-in is cancelled/fails', () async {
      final mockSignIn = MockGoogleSignIn();
      mockSignIn.mockAccount = null;

      final service = GoogleDriveService(googleSignIn: mockSignIn);
      expect(service.isSignedIn, isFalse);

      final result = await service.signIn();
      expect(result.isLeft(), isTrue);
      expect(service.isSignedIn, isFalse);

      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });
  });

  group('GoogleDriveService - Sign-Out', () {
    test('signOut signs out of googleSignIn and clears client', () async {
      final mockSignIn = MockGoogleSignIn();
      final mockAccount = MockGoogleSignInAccount({'Authorization': 'Bearer test-token'});
      mockSignIn.mockAccount = mockAccount;

      final service = GoogleDriveService(googleSignIn: mockSignIn);
      await service.signIn();
      expect(service.isSignedIn, isTrue);

      final result = await service.signOut();
      expect(result.isRight(), isTrue);
      expect(service.isSignedIn, isFalse);
      expect(mockSignIn.signOutCalled, isTrue);
    });

    test('disconnect revokes credentials, resets drive client, and returns Right(unit)', () async {
      final mockSignIn = MockGoogleSignIn();
      final mockAccount = MockGoogleSignInAccount({'Authorization': 'Bearer test-token'});
      mockSignIn.mockAccount = mockAccount;

      final service = GoogleDriveService(googleSignIn: mockSignIn);
      await service.signIn();
      expect(service.isSignedIn, isTrue);

      final result = await service.disconnect();
      expect(result.isRight(), isTrue);
      expect(service.isSignedIn, isFalse);
      expect(mockSignIn.disconnectCalled, isTrue);
    });
  });

  group('GoogleDriveService - CRUD - List Files', () {
    test('listFiles returns Left(GoogleDriveAuthenticationFailure) when not authenticated', () async {
      final service = GoogleDriveService();
      expect(service.isSignedIn, isFalse);

      final result = await service.listFiles();
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });

    test('listFiles returns file list on success when authenticated', () async {
      final mockHttpClient = MockHttpClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, contains('/drive/v3/files'));
        expect(request.url.queryParameters['spaces'], equals('appDataFolder'));

        final jsonResponse = {
          'kind': 'drive#fileList',
          'files': [
            {
              'kind': 'drive#file',
              'id': 'file123',
              'name': 'test.txt',
              'mimeType': 'text/plain'
            }
          ]
        };

        return http.Response(
          json.encode(jsonResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);
      expect(service.isSignedIn, isTrue);

      final result = await service.listFiles();
      expect(result.isRight(), isTrue);

      final files = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(files.length, equals(1));
      expect(files[0].id, equals('file123'));
      expect(files[0].name, equals('test.txt'));
    });

    test('listFiles returns Left(GoogleDriveUnknownFailure) when api returns error', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.listFiles();
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveUnknownFailure>());
    });
  });

  group('GoogleDriveService - CRUD - Upload File', () {
    test('uploadFile returns Left(GoogleDriveAuthenticationFailure) when not authenticated', () async {
      final service = GoogleDriveService();
      expect(service.isSignedIn, isFalse);

      final result = await service.uploadFile('test.txt', [1, 2, 3]);
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });

    test('uploadFile sends correct post request and returns drive.File on success', () async {
      final mockHttpClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, contains('/upload/drive/v3/files'));

        final jsonResponse = {
          'kind': 'drive#file',
          'id': 'newFile123',
          'name': 'backup.txt',
          'mimeType': 'text/plain'
        };

        return http.Response(
          json.encode(jsonResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.uploadFile('backup.txt', utf8.encode('file-content'), mimeType: 'text/plain');
      expect(result.isRight(), isTrue);

      final file = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(file.id, equals('newFile123'));
      expect(file.name, equals('backup.txt'));
    });

    test('uploadFile returns Left(GoogleDriveUnknownFailure) when api returns error', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Bad Request', 400);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.uploadFile('backup.txt', [1, 2, 3]);
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveUnknownFailure>());
    });
  });

  group('GoogleDriveService - CRUD - Download File', () {
    test('downloadFile returns Left(GoogleDriveAuthenticationFailure) when not authenticated', () async {
      final service = GoogleDriveService();
      expect(service.isSignedIn, isFalse);

      final result = await service.downloadFile('file123');
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });

    test('downloadFile returns bytes on success when authenticated', () async {
      final mockHttpClient = MockHttpClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, contains('/drive/v3/files/file123'));
        expect(request.url.queryParameters['alt'], equals('media'));

        return http.Response(
          'hello-world-downloaded',
          200,
          headers: {'content-type': 'text/plain'},
        );
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.downloadFile('file123');
      expect(result.isRight(), isTrue);

      final bytes = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(utf8.decode(bytes), equals('hello-world-downloaded'));
    });

    test('downloadFile returns Left(GoogleDriveFileNotFoundFailure) when file not found (404)', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Not Found', 404);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.downloadFile('nonexistent');
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveFileNotFoundFailure>());
    });

    test('downloadFile returns Left(GoogleDriveUnknownFailure) when api returns other error', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.downloadFile('file123');
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveUnknownFailure>());
    });
  });

  group('GoogleDriveService - CRUD - Delete File', () {
    test('deleteFile returns Left(GoogleDriveAuthenticationFailure) when not authenticated', () async {
      final service = GoogleDriveService();
      expect(service.isSignedIn, isFalse);

      final result = await service.deleteFile('file123');
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });

    test('deleteFile calls API and returns Right(unit) on success when authenticated', () async {
      final mockHttpClient = MockHttpClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, contains('/drive/v3/files/file123'));

        return http.Response('', 204);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.deleteFile('file123');
      expect(result.isRight(), isTrue);
    });

    test('deleteFile returns Left(GoogleDriveFileNotFoundFailure) when file not found (404)', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Not Found', 404);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.deleteFile('nonexistent');
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveFileNotFoundFailure>());
    });

    test('deleteFile returns Left(GoogleDriveUnknownFailure) when api returns other error', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.deleteFile('file123');
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveUnknownFailure>());
    });
  });

  group('GoogleDriveService - CRUD - Update File', () {
    test('updateFile returns Left(GoogleDriveAuthenticationFailure) when not authenticated', () async {
      final service = GoogleDriveService();
      expect(service.isSignedIn, isFalse);

      final result = await service.updateFile('file123', [1, 2, 3]);
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });

    test('updateFile sends correct patch/put request and returns drive.File on success', () async {
      final mockHttpClient = MockHttpClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, contains('/upload/drive/v3/files/file123'));

        final jsonResponse = {
          'kind': 'drive#file',
          'id': 'file123',
          'name': 'updated.txt',
          'mimeType': 'text/plain'
        };

        return http.Response(
          json.encode(jsonResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.updateFile('file123', utf8.encode('updated-content'), mimeType: 'text/plain');
      expect(result.isRight(), isTrue);

      final file = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(file.id, equals('file123'));
      expect(file.name, equals('updated.txt'));
    });

    test('updateFile returns Left(GoogleDriveFileNotFoundFailure) when file not found (404)', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Not Found', 404);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.updateFile('nonexistent', [1, 2, 3]);
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveFileNotFoundFailure>());
    });

    test('updateFile returns Left(GoogleDriveUnknownFailure) when api returns other error', () async {
      final mockHttpClient = MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(driveApi: driveApi);

      final result = await service.updateFile('file123', [1, 2, 3]);
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveUnknownFailure>());
    });
  });

  group('GoogleDriveService - Purge App Data Folder', () {
    test('purgeAppDataFolder returns Left(GoogleDriveAuthenticationFailure) when not authenticated', () async {
      final service = GoogleDriveService();
      expect(service.isSignedIn, isFalse);

      final result = await service.purgeAppDataFolder();
      expect(result.isLeft(), isTrue);
      final failure = result.swap().getOrElse((_) => throw Exception('Expected Left'));
      expect(failure, isA<GoogleDriveAuthenticationFailure>());
    });

    test('purgeAppDataFolder lists, deletes all files, and signs out on success', () async {
      final mockSignIn = MockGoogleSignIn();
      final mockAccount = MockGoogleSignInAccount({'Authorization': 'Bearer test-token'});
      mockSignIn.mockAccount = mockAccount;

      final deletedFiles = <String>[];
      final mockHttpClient = MockHttpClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/drive/v3/files')) {
          final jsonResponse = {
            'kind': 'drive#fileList',
            'files': [
              {'kind': 'drive#file', 'id': 'file1', 'name': 'note1.md'},
              {'kind': 'drive#file', 'id': 'file2', 'name': 'note2.md'},
            ]
          };
          return http.Response(json.encode(jsonResponse), 200, headers: {'content-type': 'application/json'});
        } else if (request.method == 'DELETE') {
          final fileId = request.url.pathSegments.last;
          deletedFiles.add(fileId);
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final driveApi = drive.DriveApi(mockHttpClient);
      final service = GoogleDriveService(googleSignIn: mockSignIn, driveApi: driveApi);

      expect(service.isSignedIn, isTrue);

      final result = await service.purgeAppDataFolder();
      expect(result.isRight(), isTrue);

      expect(deletedFiles, equals(['file1', 'file2']));
      expect(mockSignIn.signOutCalled, isTrue);
      expect(service.isSignedIn, isFalse);
    });
  });
}

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      contentLength: response.contentLength,
      reasonPhrase: response.reasonPhrase,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
    );
  }
}
