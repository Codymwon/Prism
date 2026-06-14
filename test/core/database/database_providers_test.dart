import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/database/database_helper.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/features/notes/data/vault_service.dart';
import 'package:prism/features/notes/data/note_model.dart';

class StubNoteIngestionService implements NoteIngestionService {
  bool syncVaultCalled = false;

  @override
  Future<void> syncVault(String vaultPath) async {
    syncVaultCalled = true;
    return;
  }

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Note> createGhostNote(String title) {
    throw UnimplementedError();
  }

  @override
  Future<Note?> getNoteById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Note?> getNoteByTitle(String title) {
    throw UnimplementedError();
  }

  @override
  Future<Note?> getDailyNote(String date) {
    throw UnimplementedError();
  }

  @override
  Future<String> readNoteContent(String noteId) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveNote(String id, String content) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteNote(String id) {
    throw UnimplementedError();
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late StubNoteIngestionService stubIngestionService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_database_prov_test');
    stubIngestionService = StubNoteIngestionService();
    SharedPreferences.setMockInitialValues({'welcomeNotesSeeded': true});
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('databaseProvider triggers syncVault and increments both version providers upon completion', () async {
    final container = ProviderContainer(
      overrides: [
        activeVaultPathProvider.overrideWith((ref) async => tempDir.path),
        noteIngestionServiceProvider.overrideWith((ref) => stubIngestionService),
      ],
    );

    // Keep the databaseProvider and version providers alive during the test
    final subscription = container.listen(databaseProvider, (_, next) {});
    final notesSub = container.listen(notesVersionProvider, (_, next) {});
    final foldersSub = container.listen(foldersVersionProvider, (_, next) {});

    // Initial versions should be 0
    expect(container.read(notesVersionProvider), equals(0));
    expect(container.read(foldersVersionProvider), equals(0));

    // Await database connection initialization
    final db = await container.read(databaseProvider.future);
    expect(db.isOpen, isTrue);

    // Wait a brief moment for the background sync to complete
    await Future.delayed(const Duration(milliseconds: 200));

    // Assert that syncVault was called
    expect(stubIngestionService.syncVaultCalled, isTrue);

    // Assert that both version providers were incremented
    expect(container.read(notesVersionProvider), equals(1));
    expect(container.read(foldersVersionProvider), equals(1));

    subscription.close();
    notesSub.close();
    foldersSub.close();
    container.dispose();
    // Ensure database connection is closed to release file lock before tearing down
    await DatabaseHelper.instance.closeDatabaseConnection(db);
  });


}
