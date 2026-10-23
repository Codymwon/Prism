import 'package:path/path.dart' as p;
import '../../../../core/database/database_service.dart';
import '../../../../core/utils/utils.dart' as utils;
import '../metadata_indexer.dart';
import '../note_content_parser.dart';

class SqfliteExecutorWrapper implements DbExecutor {
  final DatabaseExecutor executor;
  SqfliteExecutorWrapper(this.executor);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
  }) {
    return executor.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    int? conflictAlgorithm,
  }) {
    return executor.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm != null
          ? ConflictAlgorithm.values[conflictAlgorithm]
          : null,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    int? conflictAlgorithm,
  }) {
    return executor.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm != null
          ? ConflictAlgorithm.values[conflictAlgorithm]
          : null,
    );
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return executor.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}

class SqliteMetadataIndexer implements MetadataIndexer {
  final void Function(Set<DbTable> tables)? onTablesChanged;

  SqliteMetadataIndexer({this.onTablesChanged});

  @override
  Future<Set<DbTable>> indexNote(
    DbExecutor executor, {
    required String id,
    required String title,
    required String filePath,
    required int wordCount,
    required DateTime updatedAt,
    required bool isGhost,
    required bool isDaily,
    required String? dailyDate,
    required String vaultPath,
    required NoteMetadata metadata,
  }) async {
    final existing = await executor.query(
      'notes',
      columns: ['title', 'created_at', 'is_daily', 'daily_date'],
      where: 'id = ?',
      whereArgs: [id],
    );

    final bool isNew = existing.isEmpty;
    final String? oldTitle = isNew ? null : existing.first['title'] as String?;
    final bool titleChanged = isNew || oldTitle != title;
    final nowMs = updatedAt.millisecondsSinceEpoch;

    if (isNew) {
      await executor.insert('notes', {
        'id': id,
        'title': title,
        'file_path': filePath,
        'word_count': wordCount,
        'created_at': nowMs,
        'updated_at': nowMs,
        'is_ghost': isGhost ? 1 : 0,
        'is_daily': isDaily ? 1 : 0,
        'daily_date': dailyDate,
        'is_conflicted': 0,
        'original_note_id': null,
        'snippet': metadata.snippet,
      });
    } else {
      final old = existing.first;
      await executor.update('notes', {
        'title': title,
        'file_path': filePath,
        'word_count': wordCount,
        'updated_at': nowMs,
        'is_ghost': isGhost ? 1 : 0,
        'is_daily': isDaily ? 1 : (old['is_daily'] ?? 0),
        'daily_date': dailyDate ?? old['daily_date'],
        'snippet': metadata.snippet,
      }, where: 'id = ?', whereArgs: [id]);
    }

    // Rebuild full-text search (FTS5) index
    try {
      await executor.delete('notes_fts', where: 'id = ?', whereArgs: [id]);
      if (!isGhost) {
        await executor.insert('notes_fts', {
          'id': id,
          'title': title,
          'body': metadata.body,
        });
      }
    } catch (_) {
      // notes_fts table might not exist in isolated test schemas
    }

    // Diff tags: only update note_tags if tags actually changed
    final existingTagsRows = await executor.query(
      'note_tags',
      columns: ['tag'],
      where: 'note_id = ?',
      whereArgs: [id],
    );
    final oldTags = existingTagsRows.map((r) => (r['tag'] as String).toLowerCase()).toSet();
    final newTags = metadata.tags.map((t) => t.toLowerCase()).toSet();
    final bool tagsChanged = isNew
        ? newTags.isNotEmpty
        : (oldTags.length != newTags.length || !oldTags.containsAll(newTags));

    if (tagsChanged) {
      await executor.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
      for (final tag in metadata.tags) {
        await executor.insert(
          'note_tags',
          {'note_id': id, 'tag': tag.toLowerCase()},
          conflictAlgorithm: ConflictAlgorithm.ignore.index,
        );
      }
    }

    // Diff wikilinks: only update note_links if links or title changed
    final Map<String, String> titleToIdMap = {};
    if (metadata.wikilinks.isNotEmpty) {
      final placeholders = List.filled(metadata.wikilinks.length, '?').join(', ');
      final targetMaps = await executor.query(
        'notes',
        columns: ['id', 'title'],
        where: 'title COLLATE NOCASE IN ($placeholders)',
        whereArgs: metadata.wikilinks,
      );
      for (final row in targetMaps) {
        final t = row['title'] as String;
        final noteId = row['id'] as String;
        titleToIdMap[t.toLowerCase()] = noteId;
      }
    }

    final existingLinksRows = await executor.query(
      'note_links',
      columns: ['target_id', 'context_snippet'],
      where: 'source_id = ?',
      whereArgs: [id],
    );

    bool linksChanged = titleChanged || isNew;
    if (!linksChanged) {
      final hasNewGhostTargets = metadata.wikilinks.any(
        (t) => !titleToIdMap.containsKey(t.toLowerCase()),
      );
      if (hasNewGhostTargets) {
        linksChanged = true;
      } else if (existingLinksRows.length != metadata.wikilinks.length) {
        linksChanged = true;
      } else {
        final existingTargetSnippets = <String, String?>{
          for (final row in existingLinksRows)
            row['target_id'] as String: row['context_snippet'] as String?,
        };
        for (final target in metadata.wikilinks) {
          final targetId = titleToIdMap[target.toLowerCase()];
          if (targetId == null || !existingTargetSnippets.containsKey(targetId)) {
            linksChanged = true;
            break;
          }
        }
      }
    }

    if (linksChanged) {
      await executor.delete('note_links', where: 'source_id = ?', whereArgs: [id]);

      for (final target in metadata.wikilinks) {
        String? targetId = titleToIdMap[target.toLowerCase()];
        if (targetId == null) {
          // Create a target ghost note inside this transaction
          targetId = utils.generateId();
          final slug = utils.titleToSlug(target);
          final fileName = '$slug-$targetId.md';
          final targetFilePath = p.join(vaultPath, fileName);

          await executor.insert('notes', {
            'id': targetId,
            'title': target,
            'file_path': targetFilePath,
            'word_count': 0,
            'created_at': nowMs,
            'updated_at': nowMs,
            'is_ghost': 1,
            'is_daily': 0,
            'daily_date': null,
            'is_conflicted': 0,
            'original_note_id': null,
            'snippet': '',
          });
          titleToIdMap[target.toLowerCase()] = targetId;
        }

        final snippet = metadata.wikilinkContexts[target];
        await executor.insert(
          'note_links',
          {
            'source_id': id,
            'target_id': targetId,
            'context_snippet': snippet,
            'created_at': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace.index,
        );
      }
    }

    final changedTables = <DbTable>{DbTable.notes};
    if (tagsChanged) changedTables.add(DbTable.noteTags);
    if (linksChanged) changedTables.add(DbTable.noteLinks);
    onTablesChanged?.call(changedTables);
    return changedTables;
  }

  @override
  Future<Set<DbTable>> removeNoteIndex(DbExecutor executor, String id) async {
    await executor.delete('notes', where: 'id = ?', whereArgs: [id]);
    try {
      await executor.delete('notes_fts', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      // notes_fts table might not exist in isolated test schemas
    }
    final changedTables = <DbTable>{DbTable.notes, DbTable.noteTags, DbTable.noteLinks};
    onTablesChanged?.call(changedTables);
    return changedTables;
  }
}
