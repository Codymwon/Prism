import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';

part 'folders_providers.g.dart';

// ─── Selected Folder Provider ────────────────────────────────────────────────
@riverpod
class SelectedFolderId extends _$SelectedFolderId {
  @override
  String? build() => null;

  @override
  String? get state => super.state;

  @override
  set state(String? value) => super.state = value;
}

// ─── Folders Provider ─────────────────────────────────────────────────────────
@riverpod
Future<List<VirtualFolder>> folders(FoldersRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getAllFolders();
}

// ─── Folders for Note Provider ────────────────────────────────────────────────
@riverpod
Future<List<VirtualFolder>> foldersForNote(FoldersForNoteRef ref, String noteId) async {
  await ref.watch(databaseProvider.future);
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getFoldersForNote(noteId);
}

// ─── Note-Folder Mappings Provider ────────────────────────────────────────────
@riverpod
Future<Map<String, List<String>>> noteFolderMappings(NoteFolderMappingsRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getNoteFolderMappings();
}
