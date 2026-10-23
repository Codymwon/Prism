import '../../../core/database/database_service.dart';
import 'audio_bookmark_model.dart';

/// Repository for CRUD operations on audio bookmark timestamps.
/// Bookmarks are stored in the [audio_bookmarks] table (added in DB v4).
class AudioBookmarkRepository {
  final Future<dynamic> Function() _getDatabase;
  final Future<String> Function()? _getVaultPath;

  AudioBookmarkRepository(this._getDatabase, [this._getVaultPath]);

  Future<DatabaseService> _db() async {
    final raw = await _getDatabase();
    if (raw is DatabaseService) return raw;
    if (raw is DatabaseExecutor) return SqliteDatabaseService(raw);
    throw StateError('Unsupported db type: ${raw.runtimeType}');
  }

  Future<void> _flush(DatabaseService db) async {
    if (_getVaultPath != null) {
      final vaultPath = await _getVaultPath();
      await db.flushMetadata(vaultPath);
    }
  }

  /// Returns all bookmarks for a given [noteId] and [attachmentPath],
  /// sorted ascending by [timestampMs].
  Future<List<AudioBookmark>> getBookmarksForAttachment(
    String noteId,
    String attachmentPath,
  ) async {
    final db = await _db();
    final rows = await db.query(
      'audio_bookmarks',
      where: 'note_id = ? AND attachment_path = ?',
      whereArgs: [noteId, attachmentPath],
      orderBy: 'timestamp_ms ASC',
    );
    return rows.map(AudioBookmark.fromMap).toList();
  }

  /// Inserts a new [bookmark] into the database, updates the sidecar, and emits change events.
  Future<void> addBookmark(AudioBookmark bookmark) async {
    final db = await _db();
    await db.insert(
      'audio_bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    db.notifyTableChanged(DbTable.audioBookmarks);
    await _flush(db);
  }

  /// Deletes the bookmark with the given [bookmarkId], updates the sidecar, and emits change events.
  Future<void> deleteBookmark(String bookmarkId) async {
    final db = await _db();
    await db.delete(
      'audio_bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
    db.notifyTableChanged(DbTable.audioBookmarks);
    await _flush(db);
  }
}
