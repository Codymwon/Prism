import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/note_model.dart';
import '../../data/note_repository.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_repository.dart';
import '../../../folders/data/folder_model.dart';

// ─── Notes List Providers ─────────────────────────────────────────────────────

final noteSortProvider = StateProvider<NoteSort>((ref) => NoteSort.updated);

final notesProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  ref.watch(notesVersionProvider);
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  final sort = ref.watch(noteSortProvider);
  
  final folderId = ref.watch(selectedFolderIdProvider);
  if (folderId != null) {
    final folderRepo = ref.watch(folderRepositoryProvider);
    return folderRepo.getNotesInFolder(folderId, sort: sort);
  }
  
  return repo.getAllNotes(sort: sort);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  ref.watch(notesVersionProvider);
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(noteRepositoryProvider);
  if (query.trim().isEmpty) return [];
  
  bool didDispose = false;
  ref.onDispose(() => didDispose = true);
  
  await Future.delayed(const Duration(milliseconds: 250));
  if (didDispose) return [];
  
  return repo.searchNotes(query);
});

final autocompleteSuggestionsProvider = FutureProvider.autoDispose.family<List<Note>, String>((ref, query) async {
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  if (query.trim().isEmpty) return [];
  
  bool didDispose = false;
  ref.onDispose(() => didDispose = true);
  
  await Future.delayed(const Duration(milliseconds: 150));
  if (didDispose) return [];
  
  return repo.getTitleSuggestions(query);
});

final noteByIdProvider = FutureProvider.autoDispose.family<Note?, String>((ref, id) async {
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNoteById(id);
});

final backlinksProvider = FutureProvider.autoDispose.family<List<Backlink>, String>((ref, noteId) async {
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getBacklinks(noteId);
});

final graphDataProvider = FutureProvider.autoDispose<({List<GraphNode> nodes, List<GraphEdge> edges})>((ref) async {
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getGraphData();
});

class HomeScreenData {
  final List<Note> notes;
  final List<VirtualFolder> folders;
  final Map<String, List<String>> mappings;

  HomeScreenData({
    required this.notes,
    required this.folders,
    required this.mappings,
  });
}

final homeScreenDataProvider = FutureProvider.autoDispose<HomeScreenData>((ref) async {
  final notes = await ref.watch(notesProvider.future);
  final folders = await ref.watch(foldersProvider.future);
  final mappings = await ref.watch(noteFolderMappingsProvider.future);

  return HomeScreenData(
    notes: notes,
    folders: folders,
    mappings: mappings,
  );
});
