import 'package:sqflite/sqflite.dart';
import 'note_content_parser.dart';

abstract class MetadataIndexer {
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
  });
  
  Future<void> removeNoteIndex(DatabaseExecutor executor, String id);
}
