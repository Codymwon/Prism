import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/utils.dart' as utils;
import '../metadata_indexer.dart';
import '../note_content_parser.dart';

class SqliteMetadataIndexer implements MetadataIndexer {
  @override
  Future<void> indexNote(
    DatabaseExecutor executor, {
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
      columns: ['created_at', 'is_daily', 'daily_date'],
      where: 'id = ?',
      whereArgs: [id],
    );

    final nowMs = updatedAt.millisecondsSinceEpoch;

    if (existing.isEmpty) {
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
      }, where: 'id = ?', whereArgs: [id]);
    }

    // Rebuild tags
    await executor.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
    for (final tag in metadata.tags) {
      await executor.insert(
        'note_tags',
        {'note_id': id, 'tag': tag.toLowerCase()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Rebuild wikilinks
    await executor.delete('note_links', where: 'source_id = ?', whereArgs: [id]);
    for (final target in metadata.wikilinks) {
      final targetMaps = await executor.query(
        'notes',
        columns: ['id'],
        where: 'LOWER(title) = ?',
        whereArgs: [target.toLowerCase()],
      );

      String targetId;
      if (targetMaps.isEmpty) {
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
        });
      } else {
        targetId = targetMaps.first['id'] as String;
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
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<void> removeNoteIndex(DatabaseExecutor executor, String id) async {
    await executor.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
