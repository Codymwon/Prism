import 'package:sqflite/sqflite.dart';
import 'audio_bookmark_model.dart';

/// Repository for CRUD operations on audio bookmark timestamps.
/// Bookmarks are stored in the [audio_bookmarks] table (added in DB v4).
class AudioBookmarkRepository {
  final Future<Database> Function() _getDatabase;

  AudioBookmarkRepository(this._getDatabase);

  Future<Database> _db() async {
    return _getDatabase();
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

  /// Inserts a new [bookmark] into the database.
  Future<void> addBookmark(AudioBookmark bookmark) async {
    final db = await _db();
    await db.insert(
      'audio_bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes the bookmark with the given [bookmarkId].
  Future<void> deleteBookmark(String bookmarkId) async {
    final db = await _db();
    await db.delete(
      'audio_bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }
}
