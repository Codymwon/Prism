import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../features/folders/data/folder_repository.dart';
import '../../features/notes/data/note_repository.dart';
import '../database/vault_providers.dart';
import 'markdown_pdf_renderer.dart';

// ─── Failure Types ────────────────────────────────────────────────────────────

sealed class VaultExportFailure {
  final String message;
  const VaultExportFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class ExportIoFailure extends VaultExportFailure {
  const ExportIoFailure(super.message);
}

class ExportEmptyFailure extends VaultExportFailure {
  const ExportEmptyFailure(super.message);
}

class ExportCancelledFailure extends VaultExportFailure {
  const ExportCancelledFailure(super.message);
}

// ─── Result Type ──────────────────────────────────────────────────────────────

class VaultExportResult {
  final String savedPath;
  final int bytes;
  final int noteCount;

  const VaultExportResult({
    required this.savedPath,
    required this.bytes,
    required this.noteCount,
  });
}

// ─── Format Enum ─────────────────────────────────────────────────────────────

enum ExportFormat { zipArchive, pdfCompiled, pdfZipped, json }

// ─── Abstract Service ─────────────────────────────────────────────────────────

abstract class VaultExportService {
  Future<Either<VaultExportFailure, VaultExportResult>> export(
    ExportFormat format, {
    required void Function(double progress, String label) onProgress,
  });
}

final vaultExportServiceProvider = Provider<VaultExportService>(
  (ref) => VaultExportServiceImpl(ref),
);

// ─── Implementation ───────────────────────────────────────────────────────────

class VaultExportServiceImpl implements VaultExportService {
  final Ref _ref;

  VaultExportServiceImpl(this._ref);

  // ── Testability seam ───────────────────────────────────────────────────────
  //
  // Tests subclass this and override [saveBytes] to write to a temp directory
  // instead of showing a platform file picker dialog.

  /// Shows a platform save-file dialog and writes [bytes].
  /// Returns the saved path, or null if the user cancelled.
  @visibleForTesting
  Future<String?> saveBytes(String fileName, List<int> bytes) =>
      FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns a yyyyMMdd_HHmmss timestamp for file naming.
  String _dateStamp() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$y$mo${d}_$h$mi$s';
  }

  /// Converts a note title to a kebab-case slug (≤50 chars) + 8-char ID suffix.
  /// Guarantees uniqueness even when two notes share the same title.
  String _slug(String title, String id) {
    final raw = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final trimmed = raw.isEmpty ? 'note' : raw.substring(0, min(50, raw.length));
    final suffix = id.substring(0, min(8, id.length));
    return '$trimmed-$suffix';
  }

  // ── Dispatch ───────────────────────────────────────────────────────────────

  @override
  Future<Either<VaultExportFailure, VaultExportResult>> export(
    ExportFormat format, {
    required void Function(double progress, String label) onProgress,
  }) async {
    try {
      return switch (format) {
        ExportFormat.json => await _exportJson(onProgress),
        ExportFormat.zipArchive => await _exportZipArchive(onProgress),
        ExportFormat.pdfCompiled => await _exportPdfCompiled(onProgress),
        ExportFormat.pdfZipped => await _exportPdfZipped(onProgress),
      };
    } catch (e) {
      return Left(ExportIoFailure('Unexpected export error: $e'));
    }
  }

  // ── Task 11: JSON Export ───────────────────────────────────────────────────

  Future<Either<VaultExportFailure, VaultExportResult>> _exportJson(
    void Function(double, String) onProgress,
  ) async {
    // Export is intentionally plaintext: user accepted this by initiating the export.
    onProgress(0.0, 'Preparing export…');

    final repo = _ref.read(noteRepositoryProvider);
    final folderRepo = _ref.read(folderRepositoryProvider);

    final notes = await repo.getAllNotes();
    if (notes.isEmpty) {
      return const Left(ExportEmptyFailure('No notes found in this vault.'));
    }

    final vaultName = await _ref.read(activeVaultNameProvider.future);
    final noteFolderMap = await folderRepo.getNoteFolderMappings();
    final allFolders = await folderRepo.getAllFolders();

    // Collect all note data on the main isolate (DB + file reads must stay here).
    final noteDataList = <Map<String, dynamic>>[];
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      final content = await repo.readNoteContent(n.id);
      final tags = await repo.getTagsForNote(n.id);
      final backlinks = await repo.getBacklinks(n.id);
      final folderIds = noteFolderMap[n.id] ?? [];
      final folderNames = folderIds
          .map((fid) => allFolders.firstWhereOrNull((f) => f.id == fid)?.name)
          .whereType<String>()
          .toList();

      noteDataList.add({
        'id': n.id,
        'title': n.title,
        'content': content, // raw .md including frontmatter (by design)
        'tags': tags,
        'backlinks': backlinks
            .map((b) => {
                  'sourceId': b.sourceId,
                  'sourceTitle': b.sourceTitle,
                  'contextSnippet': b.contextSnippet, // may be null; already trimmed by indexer
                })
            .toList(),
        'folders': folderNames,
        'wordCount': n.wordCount,
        'snippet': n.snippet,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      });
    }

    onProgress(0.5, 'Encoding JSON…');

    // Heavy JSON encoding runs in an isolate to keep UI responsive.
    final exportedAt = DateTime.now().toIso8601String();
    final jsonBytes = await Isolate.run(() {
      final payload = {
        'version': 1,
        'exportedAt': exportedAt,
        'vaultName': vaultName,
        'notes': noteDataList,
      };
      return utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
    });

    onProgress(0.9, 'Saving file…');

    final saved = await saveBytes(
      'prism-export-${_dateStamp()}.json',
      jsonBytes,
    );

    if (saved == null) {
      return const Left(ExportCancelledFailure('Save cancelled by user.'));
    }

    onProgress(1.0, 'Done');
    return Right(VaultExportResult(
      savedPath: saved,
      bytes: jsonBytes.length,
      noteCount: notes.length,
    ));
  }

  // ── Task 12: ZIP Archive Export ────────────────────────────────────────────

  Future<Either<VaultExportFailure, VaultExportResult>> _exportZipArchive(
    void Function(double, String) onProgress,
  ) async {
    onProgress(0.0, 'Scanning vault…');

    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    if (vaultPath.isEmpty) {
      return const Left(ExportIoFailure('Vault path is not configured.'));
    }

    // Collect files: *.md at vault root + attachments/** (no templates, per decision).
    final filePaths = <String>[];

    final rootDir = Directory(vaultPath);
    if (!await rootDir.exists()) {
      return const Left(ExportIoFailure('Vault directory does not exist.'));
    }

    await for (final entity in rootDir.list(recursive: false)) {
      if (entity is File && p.extension(entity.path) == '.md') {
        filePaths.add(entity.path);
      }
    }

    final attachDir = Directory(p.join(vaultPath, 'attachments'));
    if (await attachDir.exists()) {
      await for (final entity in attachDir.list(recursive: true)) {
        if (entity is File) {
          filePaths.add(entity.path);
        }
      }
    }

    if (filePaths.isEmpty) {
      return const Left(ExportEmptyFailure('No notes or attachments found to export.'));
    }

    onProgress(0.2, 'Building archive…');

    // Read file bytes on main isolate (filesystem access), then build ZIP in isolate.
    final fileEntries = <({String relPath, List<int> bytes})>[];
    for (final path in filePaths) {
      final bytes = await File(path).readAsBytes();
      final relPath = p.relative(path, from: vaultPath).replaceAll('\\', '/');
      fileEntries.add((relPath: relPath, bytes: bytes));
    }

    onProgress(0.5, 'Compressing…');

    final zipBytes = await Isolate.run(() {
      final archive = Archive();
      for (final entry in fileEntries) {
        archive.addFile(ArchiveFile(entry.relPath, entry.bytes.length, entry.bytes));
      }
      return ZipEncoder().encode(archive);
    });

    if (zipBytes.isEmpty) {
      return const Left(ExportIoFailure('Failed to encode ZIP archive.'));
    }

    onProgress(0.9, 'Saving file…');

    final saved = await saveBytes(
      'prism-vault-${_dateStamp()}.zip',
      zipBytes,
    );

    if (saved == null) {
      return const Left(ExportCancelledFailure('Save cancelled by user.'));
    }

    onProgress(1.0, 'Done');
    return Right(VaultExportResult(
      savedPath: saved,
      bytes: zipBytes.length,
      noteCount: filePaths.where((f) => p.extension(f) == '.md').length,
    ));
  }

  // ── Task 13: Compiled PDF Export ───────────────────────────────────────────

  Future<Either<VaultExportFailure, VaultExportResult>> _exportPdfCompiled(
    void Function(double, String) onProgress,
  ) async {
    onProgress(0.0, 'Loading notes…');

    final repo = _ref.read(noteRepositoryProvider);
    final notes = await repo.getAllNotes();
    if (notes.isEmpty) {
      return const Left(ExportEmptyFailure('No notes found in this vault.'));
    }

    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    final attachmentsDir = p.join(vaultPath, 'attachments');

    final notePages = <({String title, String body})>[];
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      onProgress((i + 1) / notes.length * 0.7, 'Reading ${n.title}…');
      final content = await repo.readNoteContent(n.id);
      notePages.add((title: n.title, body: content));
    }

    onProgress(0.75, 'Rendering PDF…');

    final pdfBytes = await Isolate.run(() async {
      final doc = MarkdownPdfRenderer.buildPdf(
        notePages,
        attachmentsDir: attachmentsDir,
      );
      return await doc.save();
    });

    onProgress(0.9, 'Saving file…');

    final saved = await saveBytes(
      'prism-vault-${_dateStamp()}.pdf',
      pdfBytes,
    );

    if (saved == null) {
      return const Left(ExportCancelledFailure('Save cancelled by user.'));
    }

    onProgress(1.0, 'Done');
    return Right(VaultExportResult(
      savedPath: saved,
      bytes: pdfBytes.length,
      noteCount: notes.length,
    ));
  }

  // ── Task 14: Zipped Per-Note PDFs Export ───────────────────────────────────

  Future<Either<VaultExportFailure, VaultExportResult>> _exportPdfZipped(
    void Function(double, String) onProgress,
  ) async {
    onProgress(0.0, 'Loading notes…');

    final repo = _ref.read(noteRepositoryProvider);
    final notes = await repo.getAllNotes();
    if (notes.isEmpty) {
      return const Left(ExportEmptyFailure('No notes found in this vault.'));
    }

    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    final attachmentsDir = p.join(vaultPath, 'attachments');

    // Render+zip phases: total steps = notes.length * 2
    final total = notes.length * 2;
    final pdfEntries = <({String archivePath, List<int> bytes})>[];

    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      onProgress((i * 2) / total, 'Rendering ${n.title}…');

      final content = await repo.readNoteContent(n.id);
      final slug = _slug(n.title, n.id);
      final archivePath = 'pdfs/$slug.pdf';

      final pdfBytes = await Isolate.run(() async {
        final doc = MarkdownPdfRenderer.buildPdf(
          [(title: n.title, body: content)],
          attachmentsDir: attachmentsDir,
        );
        return await doc.save();
      });

      pdfEntries.add((archivePath: archivePath, bytes: pdfBytes));
      onProgress((i * 2 + 1) / total, 'Zipping ${n.title}…');
    }

    onProgress(0.9, 'Building ZIP…');

    final zipBytes = await Isolate.run(() {
      final archive = Archive();
      for (final entry in pdfEntries) {
        archive.addFile(ArchiveFile(entry.archivePath, entry.bytes.length, entry.bytes));
      }
      return ZipEncoder().encode(archive);
    });

    if (zipBytes.isEmpty) {
      return const Left(ExportIoFailure('Failed to encode PDF ZIP archive.'));
    }

    onProgress(0.95, 'Saving file…');

    final saved = await saveBytes(
      'prism-vault-pdfs-${_dateStamp()}.zip',
      zipBytes,
    );

    if (saved == null) {
      return const Left(ExportCancelledFailure('Save cancelled by user.'));
    }

    onProgress(1.0, 'Done');
    return Right(VaultExportResult(
      savedPath: saved,
      bytes: zipBytes.length,
      noteCount: notes.length,
    ));
  }
}
