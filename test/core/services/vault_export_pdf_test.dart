import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/services/markdown_pdf_renderer.dart';
import 'package:prism/core/services/vault_export_service.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeNoteRepository implements NoteRepository {
  final List<Note> notes;
  final Map<String, String> contents;

  _FakeNoteRepository({required this.notes, required this.contents});

  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async => notes;

  @override
  Future<String> readNoteContent(String noteId) async => contents[noteId] ?? '';

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

Note _makeNote(String id, String title) => Note(
      id: id,
      title: title,
      filePath: '',
      wordCount: 10,
      snippet: 'snippet',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 6, 1),
    );

// ─── MarkdownPdfRenderer unit tests ───────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory saveDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_pdf_test_');
    saveDir = await Directory(p.join(tempDir.path, 'saves')).create();

    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': tempDir.path,
      'activeVaultName': 'My Vault',
    });
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  // ── MarkdownPdfRenderer unit tests ──────────────────────────────────────────

  group('MarkdownPdfRenderer', () {
    test('buildPdf returns a non-empty Document for a single note', () async {
      final doc = MarkdownPdfRenderer.buildPdf([
        (title: 'My Note', body: '# My Note\n\nHello world.'),
      ]);
      final bytes = await doc.save();
      // PDF starts with %PDF
      expect(bytes.length, greaterThan(4));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), equals('%PDF'));
    });

    test('buildPdf strips frontmatter before rendering', () async {
      // If frontmatter is not stripped, "---" lines appear as content.
      // We can't easily parse the rendered text back, but we can check
      // that the returned document encodes without errors.
      final doc = MarkdownPdfRenderer.buildPdf([
        (
          title: 'Frontmatter Note',
          body: '---\ntitle: Frontmatter Note\ncreatedAt: 2025-01-01\n---\n\n# Heading\n\nBody text.',
        ),
      ]);
      final bytes = await doc.save();
      expect(bytes.length, greaterThan(4));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), equals('%PDF'));
    });

    test('buildPdf handles multiple notes as separate pages', () async {
      final notes = List.generate(
        3,
        (i) => (title: 'Note $i', body: 'Content of note $i'),
      );
      final doc = MarkdownPdfRenderer.buildPdf(notes);
      // MultiPage document — page count is at least 1 per note.
      final bytes = await doc.save();
      expect(bytes.length, greaterThan(100));
    });

    test('buildPdf handles code blocks, blockquotes, and horizontal rules without error', () async {
      const body = '''
# Complex Note

> This is a block quote.

Some paragraph text.

---

```dart
void main() => print('hello');
```

- Bullet one
- Bullet two
''';
      final doc = MarkdownPdfRenderer.buildPdf([(title: 'Complex', body: body)]);
      expect((await doc.save()).length, greaterThan(4));
    });
  });

  // ── Compiled PDF export integration tests ───────────────────────────────────

  group('VaultExportService — pdfCompiled', () {
    test('exportPdfCompiled returns ExportEmptyFailure when vault has no notes', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            _FakeNoteRepository(notes: [], contents: {}),
          ),
          vaultExportServiceProvider.overrideWith(
            (ref) => _TestableSvc(ref, saveTo: saveDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(vaultExportServiceProvider)
          .export(ExportFormat.pdfCompiled, onProgress: (_, _) {});
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ExportEmptyFailure>());
    });

    test('exportPdfCompiled produces a valid PDF file with %PDF header', () async {
      final notes = [
        _makeNote('id-1', 'Alpha'),
        _makeNote('id-2', 'Beta'),
      ];

      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            _FakeNoteRepository(
              notes: notes,
              contents: {
                'id-1': '# Alpha\n\nFirst note content.',
                'id-2': '# Beta\n\nSecond note content.',
              },
            ),
          ),
          vaultExportServiceProvider.overrideWith(
            (ref) => _TestableSvc(ref, saveTo: saveDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(vaultExportServiceProvider)
          .export(ExportFormat.pdfCompiled, onProgress: (_, _) {});

      expect(result.isRight(), isTrue,
          reason: 'Expected Right but got: ${result.getLeft().toNullable()}');

      final exportResult = result.getRight().toNullable()!;
      expect(exportResult.noteCount, equals(2));

      final pdfFile = File(exportResult.savedPath);
      expect(await pdfFile.exists(), isTrue);

      final bytes = await pdfFile.readAsBytes();
      // Valid PDF starts with %PDF
      expect(String.fromCharCodes(bytes.sublist(0, 4)), equals('%PDF'));
    });
  });

  // ── Zipped per-note PDFs export integration tests ────────────────────────────

  group('VaultExportService — pdfZipped', () {
    test('exportPdfZipped returns ExportEmptyFailure when vault has no notes', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            _FakeNoteRepository(notes: [], contents: {}),
          ),
          vaultExportServiceProvider.overrideWith(
            (ref) => _TestableSvc(ref, saveTo: saveDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(vaultExportServiceProvider)
          .export(ExportFormat.pdfZipped, onProgress: (_, _) {});
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ExportEmptyFailure>());
    });

    test('exportPdfZipped produces a ZIP with pdfs/<slug>.pdf entries each starting %PDF', () async {
      final notes = [
        _makeNote('abcd1234', 'Meeting Notes'),
        _makeNote('efgh5678', 'Project Ideas'),
      ];

      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            _FakeNoteRepository(
              notes: notes,
              contents: {
                'abcd1234': '# Meeting Notes\n\nDiscussed roadmap.',
                'efgh5678': '# Project Ideas\n\nBig plans ahead.',
              },
            ),
          ),
          vaultExportServiceProvider.overrideWith(
            (ref) => _TestableSvc(ref, saveTo: saveDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(vaultExportServiceProvider)
          .export(ExportFormat.pdfZipped, onProgress: (_, _) {});

      expect(result.isRight(), isTrue,
          reason: 'Expected Right but got: ${result.getLeft().toNullable()}');

      final exportResult = result.getRight().toNullable()!;
      expect(exportResult.noteCount, equals(2));

      final zipBytes = await File(exportResult.savedPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final names = archive.files.map((f) => f.name).toSet();

      // Each entry should be under pdfs/ and have slug format
      expect(names.length, equals(2));
      for (final name in names) {
        expect(name, startsWith('pdfs/'));
        expect(name, endsWith('.pdf'));
        // Slug contains 8-char id suffix
        expect(name, anyOf(contains('abcd1234'), contains('efgh5678')));

        // Each PDF should start with %PDF
        final entry = archive.files.firstWhere((f) => f.name == name);
        final content = entry.content as List<int>;
        expect(String.fromCharCodes(content.sublist(0, 4)), equals('%PDF'),
            reason: '$name should be a valid PDF');
      }
    });

    test('_slug produces kebab-case with ID suffix and max 50 char title', () async {
      // Indirectly verify slug via archive entry name:
      //   title = 'A Note With Special Chars!!! And More #text'
      //   id    = 'xyzabc99'  → suffix = 'xyzabc99'
      final note = _makeNote('xyzabc99', 'A Note With Special Chars!!! And More #text');

      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            _FakeNoteRepository(
              notes: [note],
              contents: {'xyzabc99': 'Simple body'},
            ),
          ),
          vaultExportServiceProvider.overrideWith(
            (ref) => _TestableSvc(ref, saveTo: saveDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(vaultExportServiceProvider)
          .export(ExportFormat.pdfZipped, onProgress: (_, _) {});
      expect(result.isRight(), isTrue);

      final zipBytes = await File(result.getRight().toNullable()!.savedPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final name = archive.files.first.name;

      // Should be kebab-case, no special chars, ends with id suffix
      expect(name, startsWith('pdfs/'));
      expect(name, contains('xyzabc99'));
      expect(name, isNot(contains('!')));
      expect(name, isNot(contains('#')));
      // Max 50 + '-' + 8 (suffix) + '.pdf' length check
      final slug = name.replaceFirst('pdfs/', '').replaceFirst('.pdf', '');
      expect(slug.length, lessThanOrEqualTo(59)); // 50 + 1 + 8
    });
  });
}
