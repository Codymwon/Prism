import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/prism_metadata_store.dart';
import '../../../core/utils/utils.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../notes/data/note_model.dart';
import 'folder_model.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository(ref);
});

// ─── Repository ───────────────────────────────────────────────────────────────
class FolderRepository {
  final Ref _ref;

  FolderRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  /// Atomically re-serialises the five app-only SQLite tables to the sidecar.
  Future<void> _flush(Database db) async {
    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    if (vaultPath.isNotEmpty) {
      await PrismMetadataStore().flushFromDatabase(db, vaultPath);
    }
  }

  // ── READ ──────────────────────────────────────────────────────────────────
  Future<Map<String, List<String>>> getNoteFolderMappings() async {
    final db = await _db;
    final maps = await db.query('note_folders');
    final Map<String, List<String>> result = {};
    for (final row in maps) {
      final noteId = row['note_id'] as String;
      final folderId = row['folder_id'] as String;
      result.putIfAbsent(noteId, () => []).add(folderId);
    }
    return result;
  }

  Future<List<VirtualFolder>> getAllFolders() async {
    final db = await _db;
    // We join with note_count to get real-time counter for each folder
    final maps = await db.rawQuery('''
      SELECT f.*, COUNT(nf.note_id) as note_count
      FROM virtual_folders f
      LEFT JOIN note_folders nf ON nf.folder_id = f.id
      GROUP BY f.id
      ORDER BY f.sort_order ASC, f.created_at ASC
    ''');
    return maps.map(VirtualFolder.fromMap).toList();
  }

  Future<List<VirtualFolder>> getFoldersForNote(String noteId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT f.* FROM virtual_folders f
      JOIN note_folders nf ON nf.folder_id = f.id
      WHERE nf.note_id = ?
      ORDER BY f.sort_order ASC, f.created_at ASC
    ''', [noteId]);
    return maps.map(VirtualFolder.fromMap).toList();
  }

  Future<List<Note>> getNotesInFolder(String folderId, {NoteSort sort = NoteSort.updated}) async {
    final db = await _db;
    final orderBy = switch (sort) {
      NoteSort.updated => 'n.updated_at DESC',
      NoteSort.created => 'n.created_at DESC',
      NoteSort.title => 'n.title ASC',
    };
    final maps = await db.rawQuery('''
      SELECT n.* FROM notes n
      JOIN note_folders nf ON nf.note_id = n.id
      WHERE nf.folder_id = ? AND n.is_ghost = 0
      ORDER BY $orderBy
    ''', [folderId]);
    return maps.map(Note.fromMap).toList();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<VirtualFolder> createFolder(String name, {String colorHex = '#7C6FF7', String icon = 'folder'}) async {
    final id = generateId();
    final now = DateTime.now();
    
    // Get highest sort order to append
    final db = await _db;
    final maxSortMap = await db.rawQuery('SELECT MAX(sort_order) as max_sort FROM virtual_folders');
    final rawMax = maxSortMap.first['max_sort'];
    final maxSort = rawMax == null ? 0
        : rawMax is int ? rawMax
        : rawMax is double ? rawMax.toInt()
        : rawMax is bool ? (rawMax ? 1 : 0)
        : int.tryParse(rawMax.toString()) ?? 0;

    final folder = VirtualFolder(
      id: id,
      name: name,
      colorHex: colorHex,
      icon: icon,
      createdAt: now,
      sortOrder: maxSort + 1,
    );

    await db.insert('virtual_folders', folder.toMap());
    _ref.read(foldersVersionProvider.notifier).state++;
    await _flush(db);
    return folder;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> updateFolder(String id, String name, String colorHex, String icon) async {
    final db = await _db;
    await db.update(
      'virtual_folders',
      {
        'name': name,
        'color_hex': colorHex,
        'icon': icon,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _ref.read(foldersVersionProvider.notifier).state++;
    await _flush(db);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteFolder(String id) async {
    final db = await _db;
    await db.delete('virtual_folders', where: 'id = ?', whereArgs: [id]);
    _ref.read(foldersVersionProvider.notifier).state++;
    await _flush(db);
  }

  // ── RELATIONS (NOTE <-> FOLDER) ──────────────────────────────────────────
  Future<void> addNoteToFolder(String noteId, String folderId) async {
    final db = await _db;
    await db.insert(
      'note_folders',
      {'note_id': noteId, 'folder_id': folderId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    _ref.read(foldersVersionProvider.notifier).state++;
    await _flush(db);
  }

  Future<void> removeNoteFromFolder(String noteId, String folderId) async {
    final db = await _db;
    await db.delete(
      'note_folders',
      where: 'note_id = ? AND folder_id = ?',
      whereArgs: [noteId, folderId],
    );
    _ref.read(foldersVersionProvider.notifier).state++;
    await _flush(db);
  }

  Future<void> setNoteFolders(String noteId, List<String> folderIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('note_folders', where: 'note_id = ?', whereArgs: [noteId]);
      for (final folderId in folderIds) {
        await txn.insert(
          'note_folders',
          {'note_id': noteId, 'folder_id': folderId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
    _ref.read(foldersVersionProvider.notifier).state++;
    await _flush(db);
  }
}
