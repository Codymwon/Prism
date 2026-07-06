import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/services/vault_export_service.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

// ─── Fake note repository (minimal — no DB needed for ZIP test) ───────────────

class _FakeNoteRepository implements NoteRepository {
  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Testable service — overrides saveBytes to write to temp dir ──────────────

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

// ─── Cancelling service — saveBytes always returns null ─────────────────────

class _CancelSvc extends VaultExportServiceImpl {
  _CancelSvc(super.ref);

  @override
  Future<String?> saveBytes(String name, List<int> bytes) async => null;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory saveDir;
  late Directory vaultDir;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_zip_test_');
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

  test('exportZipArchive returns ExportEmptyFailure when vault has no .md files', () async {
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

    final service = container.read(vaultExportServiceProvider);
    final result = await service.export(ExportFormat.zipArchive, onProgress: (_, _) {});
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ExportEmptyFailure>());
  });

  test('exportZipArchive produces a valid ZIP containing markdown notes and attachments', () async {
    // Write a couple of .md files and one attachment
    final note1 = File(p.join(vaultDir.path, 'Note One.md'));
    await note1.writeAsString('# Note One\nContent one.');

    final note2 = File(p.join(vaultDir.path, 'Note Two.md'));
    await note2.writeAsString('# Note Two\nContent two.');

    final attachDir = await Directory(p.join(vaultDir.path, 'attachments')).create();
    final attachment = File(p.join(attachDir.path, 'audio.m4a'));
    await attachment.writeAsString('fake-audio-bytes');

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

    final service = container.read(vaultExportServiceProvider);
    final result = await service.export(ExportFormat.zipArchive, onProgress: (_, _) {});

    expect(result.isRight(), isTrue,
        reason: 'Expected Right but got: ${result.getLeft().toNullable()}');

    final exportResult = result.getRight().toNullable()!;
    expect(exportResult.noteCount, equals(2)); // 2 .md files
    expect(exportResult.bytes, greaterThan(0));

    // Decode ZIP and verify entries
    final zipFile = File(exportResult.savedPath);
    expect(await zipFile.exists(), isTrue);

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final names = archive.files.map((f) => f.name).toSet();
    expect(names, contains('Note One.md'));
    expect(names, contains('Note Two.md'));
    expect(names, contains('attachments/audio.m4a'));

    // Content of Note One should match
    final noteEntry = archive.files.firstWhere((f) => f.name == 'Note One.md');
    expect(String.fromCharCodes(noteEntry.content as List<int>), contains('Content one'));
  });

  test('exportZipArchive excludes .prism/templates/ hidden dir', () async {
    // Write one note and a file in .prism/templates
    await File(p.join(vaultDir.path, 'Real Note.md')).writeAsString('# Real Note');
    final hiddenDir = await Directory(p.join(vaultDir.path, '.prism', 'templates')).create(recursive: true);
    await File(p.join(hiddenDir.path, 'my-template.md')).writeAsString('template content');

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

    final service = container.read(vaultExportServiceProvider);
    final result = await service.export(ExportFormat.zipArchive, onProgress: (_, _) {});
    expect(result.isRight(), isTrue);

    final bytes = await File(result.getRight().toNullable()!.savedPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();

    // Template inside .prism/ must NOT be in the archive
    expect(names.any((n) => n.contains('templates')), isFalse,
        reason: 'Hidden .prism/templates/ should be excluded from ZIP export');
    // Real note should be present
    expect(names, contains('Real Note.md'));
  });

  test('exportZipArchive returns ExportCancelledFailure when saveBytes returns null', () async {
    await File(p.join(vaultDir.path, 'Note.md')).writeAsString('# Note');

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        noteRepositoryProvider.overrideWithValue(_FakeNoteRepository()),
        vaultExportServiceProvider.overrideWith((ref) => _CancelSvc(ref)),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(vaultExportServiceProvider)
        .export(ExportFormat.zipArchive, onProgress: (_, _) {});
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ExportCancelledFailure>());
  });
}
