import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/vault_providers.dart';
import '../utils/utils.dart' as utils;

part 'template_service.g.dart';

// ─── Failures ────────────────────────────────────────────────────────────────

sealed class TemplateFailure {
  final String message;
  const TemplateFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class TemplateNotFoundFailure extends TemplateFailure {
  const TemplateNotFoundFailure(super.message);
}

class TemplateIoFailure extends TemplateFailure {
  const TemplateIoFailure(super.message);
}

// ─── Virtual template IDs ────────────────────────────────────────────────────

/// Prefix for virtual template note IDs, e.g. `template:Gratitude`.
///
/// Any ID starting with this prefix is treated as a custom template and is
/// read from / written to `.prism/templates/` instead of going through the
/// SQLite index. This lets the editor treat a template like a regular note.
const templateIdPrefix = 'template:';

/// Returns true if [id] is a virtual template ID.
bool isTemplateId(String id) => id.startsWith(templateIdPrefix);

// ─── Service ─────────────────────────────────────────────────────────────────

/// File I/O for custom templates stored as standard Markdown under
/// `.prism/templates/<name>.md` inside the active vault.
///
/// Templates bypass the SQLite FTS5/relations index by design — they are
/// reusable note scaffolds, not searchable notes.
class TemplateService {
  final TemplateServiceRef _ref;

  TemplateService(this._ref);

  /// Absolute path to `<vault>/.prism/templates/`, creating it on first access.
  Future<String> get _templatesDir async {
    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    final dir = Directory(p.join(vaultPath, '.prism', 'templates'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String> _pathFor(String name) async =>
      p.join(await _templatesDir, '${utils.titleToSlug(name)}.md');

  /// Extracts the template name from a virtual ID
  /// (`template:Gratitude` -> `Gratitude`).
  String nameFromId(String id) => id.substring(templateIdPrefix.length);

  Future<Either<TemplateFailure, List<String>>> listTemplates() async {
    try {
      final dir = Directory(await _templatesDir);
      if (!await dir.exists()) return const Right([]);
      final names = <String>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.md')) {
          names.add(utils.titleToSlug(p.basenameWithoutExtension(entity.path)));
        }
      }
      return Right(names);
    } catch (e) {
      return Left(TemplateIoFailure('$e'));
    }
  }

  Future<Either<TemplateFailure, String>> readTemplate(String name) async {
    try {
      final file = File(await _pathFor(name));
      if (!await file.exists()) return Left(TemplateNotFoundFailure(name));
      return Right(await file.readAsString());
    } catch (e) {
      return Left(TemplateIoFailure('$e'));
    }
  }

  Future<Either<TemplateFailure, Unit>> writeTemplate(
    String name,
    String content,
  ) async {
    try {
      await File(await _pathFor(name)).writeAsString(content);
      _ref.read(templatesVersionProvider.notifier).increment();
      return const Right(unit);
    } catch (e) {
      return Left(TemplateIoFailure('$e'));
    }
  }

  Future<Either<TemplateFailure, Unit>> deleteTemplate(String name) async {
    try {
      final file = File(await _pathFor(name));
      if (await file.exists()) {
        await file.delete();
        _ref.read(templatesVersionProvider.notifier).increment();
      }
      return const Right(unit);
    } catch (e) {
      return Left(TemplateIoFailure('$e'));
    }
  }

  Future<Either<TemplateFailure, bool>> exists(String name) async {
    try {
      return Right(await File(await _pathFor(name)).exists());
    } catch (e) {
      return Left(TemplateIoFailure('$e'));
    }
  }
}

@riverpod
TemplateService templateService(TemplateServiceRef ref) {
  return TemplateService(ref);
}

@riverpod
class TemplatesVersion extends _$TemplatesVersion {
  @override
  int build() => 0;

  void increment() => state++;
}
