import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/services/vault_export_service.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeNoteRepository implements NoteRepository {
  final List<Note> notes;
  final Map<String, String> contents;
  final Map<String, List<String>> tags;
  final Map<String, List<Backlink>> backlinks;

  _FakeNoteRepository({
    required this.notes,
    required this.contents,
    this.tags = const {},
    this.backlinks = const {},
  });

  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async => notes;

  @override
  Future<String> readNoteContent(String noteId) async => contents[noteId] ?? '';

  @override
  Future<List<String>> getTagsForNote(String noteId) async => tags[noteId] ?? [];

  @override
  Future<List<Backlink>> getBacklinks(String noteId) async => backlinks[noteId] ?? [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFolderRepository implements FolderRepository {
  final Map<String, List<String>> noteFolderMap;
  final List<VirtualFolder> folders;

  _FakeFolderRepository({
    this.noteFolderMap = const {},
    this.folders = const [],
  });

  @override
  Future<Map<String, List<String>>> getNoteFolderMappings() async => noteFolderMap;

  @override
  Future<List<VirtualFolder>> getAllFolders() async => folders;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Test data helpers ────────────────────────────────────────────────────────

Note _makeNote(String id, String title) => Note(
      id: id,
      title: title,
      filePath: '',
      wordCount: 5,
      snippet: 'snippet of $title',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 6, 1),
    );

VirtualFolder _makeFolder(String id, String name) => VirtualFolder(
      id: id,
      name: name,
      colorHex: '#7C6FF7',
      icon: 'folder',
      createdAt: DateTime(2025, 1, 1),
      sortOrder: 0,
    );

// ─── Seam: injectable FilePicker replacement ──────────────────────────────────
//
// VaultExportServiceImpl uses FilePicker.platform.saveFile.  In tests we override
// [vaultExportServiceProvider] with a [_TestableVaultExportService] that replaces
// the saveFile call with a simple write-to-tempDir seam.

class _TestableVaultExportService extends VaultExportServiceImpl {
  final String saveTo; // directory to write the file into

  _TestableVaultExportService(super.ref, {required this.saveTo});

  @override
  Future<String?> saveBytes(String fileName, List<int> bytes) async {
    final out = File(p.join(saveTo, fileName));
    await out.writeAsBytes(bytes);
    return out.path;
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late Directory saveDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_json_test_');
    saveDir = await Directory(p.join(tempDir.path, 'saves')).create();

    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': tempDir.path,
      'activeVaultName': 'Test Vault',
    });
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('exportJson returns ExportEmptyFailure when vault has no notes', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          _FakeNoteRepository(notes: [], contents: {}),
        ),
        folderRepositoryProvider.overrideWithValue(
          _FakeFolderRepository(),
        ),
        vaultExportServiceProvider.overrideWith(
          (ref) => _TestableVaultExportService(ref, saveTo: saveDir.path),
        ),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(vaultExportServiceProvider);
    final result = await service.export(ExportFormat.json, onProgress: (_, _) {});
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ExportEmptyFailure>());
  });

  test('exportJson produces valid JSON with both notes, tags, backlinks and folder name', () async {
    final note1 = _makeNote('id-1', 'Alpha Note');
    final note2 = _makeNote('id-2', 'Beta Note');
    final folder = _makeFolder('folder-A', 'Research');

    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          _FakeNoteRepository(
            notes: [note1, note2],
            contents: {
              'id-1': '# Alpha Note\nContent of alpha.',
              'id-2': '# Beta Note\nContent of beta.',
            },
            tags: {
              'id-1': ['dart', 'flutter'],
              'id-2': ['test'],
            },
            backlinks: {
              'id-2': [
                Backlink(sourceId: 'id-1', sourceTitle: 'Alpha Note', contextSnippet: '…links to Beta…'),
              ],
            },
          ),
        ),
        folderRepositoryProvider.overrideWithValue(
          _FakeFolderRepository(
            noteFolderMap: {'id-1': ['folder-A']},
            folders: [folder],
          ),
        ),
        vaultExportServiceProvider.overrideWith(
          (ref) => _TestableVaultExportService(ref, saveTo: saveDir.path),
        ),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(vaultExportServiceProvider);
    Either<VaultExportFailure, VaultExportResult>? capturedResult;
    final result = await service.export(ExportFormat.json, onProgress: (_, _) {});
    capturedResult = result;

    expect(capturedResult.isRight(), isTrue,
        reason: 'Expected Right but got: ${capturedResult.getLeft().toNullable()}');

    final exportResult = capturedResult.getRight().toNullable()!;
    expect(exportResult.noteCount, equals(2));
    expect(exportResult.bytes, greaterThan(0));

    // Parse the saved JSON
    final savedFile = File(exportResult.savedPath);
    expect(await savedFile.exists(), isTrue);

    final jsonStr = await savedFile.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Top-level schema
    expect(json['version'], equals(1));
    expect(json['vaultName'], equals('Test Vault'));
    expect(json['exportedAt'], isA<String>());
    final notes = json['notes'] as List;
    expect(notes.length, equals(2));

    // Note 1: Alpha Note
    final n1 = notes.firstWhere((n) => n['id'] == 'id-1') as Map<String, dynamic>;
    expect(n1['title'], equals('Alpha Note'));
    expect(n1['content'], contains('Content of alpha'));
    expect((n1['tags'] as List), containsAll(['dart', 'flutter']));
    expect((n1['folders'] as List), contains('Research'));
    expect((n1['backlinks'] as List), isEmpty);

    // Note 2: Beta Note — has backlink from Alpha Note
    final n2 = notes.firstWhere((n) => n['id'] == 'id-2') as Map<String, dynamic>;
    expect(n2['title'], equals('Beta Note'));
    final bl = (n2['backlinks'] as List).first as Map<String, dynamic>;
    expect(bl['sourceId'], equals('id-1'));
    expect(bl['sourceTitle'], equals('Alpha Note'));
    expect(bl['contextSnippet'], equals('…links to Beta…'));
    // Note 2 has no folder mapping
    expect((n2['folders'] as List), isEmpty);
  });

  test('exportJson gracefully skips deleted Virtual Folders (firstWhereOrNull)', () async {
    final note1 = _makeNote('id-1', 'Orphan Note');

    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          _FakeNoteRepository(
            notes: [note1],
            contents: {'id-1': 'Content'},
          ),
        ),
        folderRepositoryProvider.overrideWithValue(
          _FakeFolderRepository(
            // Note references folder-DELETED which no longer exists in allFolders
            noteFolderMap: {'id-1': ['folder-DELETED']},
            folders: [], // folder was deleted
          ),
        ),
        vaultExportServiceProvider.overrideWith(
          (ref) => _TestableVaultExportService(ref, saveTo: saveDir.path),
        ),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(vaultExportServiceProvider);
    final result = await service.export(ExportFormat.json, onProgress: (_, _) {});
    expect(result.isRight(), isTrue);

    final savedFile = File(result.getRight().toNullable()!.savedPath);
    final json = jsonDecode(await savedFile.readAsString()) as Map<String, dynamic>;
    final n = (json['notes'] as List).first as Map<String, dynamic>;
    // Deleted folder is skipped — empty list, no crash
    expect((n['folders'] as List), isEmpty);
  });
}
