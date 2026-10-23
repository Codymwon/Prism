import '../../../../core/database/database_service.dart';
import 'note_content_parser.dart';

abstract class DbExecutor {
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
  });

  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    int? conflictAlgorithm,
  });

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    int? conflictAlgorithm,
  });

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  });
}

abstract class MetadataIndexer {
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
  });
  
  Future<Set<DbTable>> removeNoteIndex(DbExecutor executor, String id);
}
