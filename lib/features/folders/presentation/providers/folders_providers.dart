import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';

// ─── Selected Folder Provider ────────────────────────────────────────────────
final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

// ─── Folders Provider ─────────────────────────────────────────────────────────
final foldersProvider = FutureProvider.autoDispose<List<VirtualFolder>>((ref) async {
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getAllFolders();
});

// ─── Folders for Note Provider ────────────────────────────────────────────────
final foldersForNoteProvider = FutureProvider.autoDispose.family<List<VirtualFolder>, String>((ref, noteId) async {
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getFoldersForNote(noteId);
});

// ─── Note-Folder Mappings Provider ────────────────────────────────────────────
final noteFolderMappingsProvider = FutureProvider.autoDispose<Map<String, List<String>>>((ref) async {
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getNoteFolderMappings();
});
