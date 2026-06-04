import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../notes/data/audio_bookmark_model.dart';

/// Repository for CRUD operations on audio bookmark timestamps.
/// Bookmarks are stored in the [audio_bookmarks] table (added in DB v4).
class AudioBookmarkRepository {
  /// A [DatabaseHelper] whose [database] getter is awaited for each operation.
  /// Can be null when [_directDb] is supplied (used in tests).
  final DatabaseHelper? _dbHelper;

  /// A directly-injected [Database] used by tests so they can supply an
  /// in-memory FFI database without going through [DatabaseHelper].
  final Future<Database> Function()? _getDatabase;

  AudioBookmarkRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _getDatabase = null;

  /// Creates a repository backed by an arbitrary [Future<Database>] factory.
  /// Intended for unit tests with sqflite_common_ffi.
  AudioBookmarkRepository.withFactory(Future<Database> Function() getDatabase)
      : _dbHelper = null,
        _getDatabase = getDatabase;

  Future<Database> _db() async {
    final factory = _getDatabase;
    if (factory != null) return factory();
    return _dbHelper!.database;
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
