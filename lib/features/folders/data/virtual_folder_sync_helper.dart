import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/utils.dart' as utils;

class VirtualFolderSyncHelper {
  static Future<void> handleNoteSync({
    required DatabaseExecutor txn,
    required String noteId,
    required String filePath,
    required int nowMs,
  }) async {
    final isClipperInbox = filePath.toLowerCase().endsWith('${Platform.pathSeparator}inbox.md') ||
        filePath.toLowerCase().endsWith('/inbox.md');

    final isWelcomeNote = filePath.toLowerCase().endsWith('${Platform.pathSeparator}welcome to prism.md') ||
        filePath.toLowerCase().endsWith('/welcome to prism.md') ||
        filePath.toLowerCase().endsWith('${Platform.pathSeparator}productivity tools guide.md') ||
        filePath.toLowerCase().endsWith('/productivity tools guide.md');

    if (isClipperInbox) {
      await _ensureFolderAndLink(txn, noteId, 'Inbox', nowMs);
    }
    if (isWelcomeNote) {
      await _ensureFolderAndLink(txn, noteId, 'Tutorial', nowMs);
    }
  }

  static Future<void> _ensureFolderAndLink(
    DatabaseExecutor txn,
    String noteId,
    String folderName,
    int nowMs,
  ) async {
    final folderMaps = await txn.query(
      'virtual_folders',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: [folderName.toLowerCase()],
    );

    String folderId;
    if (folderMaps.isEmpty) {
      folderId = utils.generateId();
      final maxSortMap = await txn.rawQuery('SELECT MAX(sort_order) as max_sort FROM virtual_folders');
      final rawMax = maxSortMap.first['max_sort'];
      final maxSort = rawMax == null ? 0 : (rawMax is int ? rawMax : int.tryParse(rawMax.toString()) ?? 0);

      await txn.insert('virtual_folders', {
        'id': folderId,
        'name': folderName,
        'color_hex': '#7C6FF7',
        'icon': 'folder',
        'created_at': nowMs,
        'sort_order': maxSort + 1,
      });
    } else {
      folderId = folderMaps.first['id'] as String;
    }

    await txn.insert(
      'note_folders',
      {'note_id': noteId, 'folder_id': folderId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
