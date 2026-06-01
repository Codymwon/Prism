import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/note_model.dart';
import '../../data/note_repository.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_repository.dart';
import '../../../folders/data/folder_model.dart';

// ─── Notes List Providers ─────────────────────────────────────────────────────

final noteSortProvider = StateProvider<NoteSort>((ref) => NoteSort.updated);

final selectedTagProvider = StateProvider<String?>((ref) => null);

final notesProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  ref.watch(notesVersionProvider);
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  final sort = ref.watch(noteSortProvider);
  
  final tag = ref.watch(selectedTagProvider);
  if (tag != null) {
    return repo.getNotesByTag(tag);
  }
  
  final folderId = ref.watch(selectedFolderIdProvider);
  if (folderId != null) {
    final folderRepo = ref.watch(folderRepositoryProvider);
    return folderRepo.getNotesInFolder(folderId, sort: sort);
  }
  
  return repo.getAllNotes(sort: sort);
});

final uniqueTagsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getUniqueTags();
});

final vaultStatsProvider = FutureProvider.autoDispose<({int totalNotes, int totalWords, int totalLinks})>((ref) async {
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getVaultStats();
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

final homeScreenDataProvider = Provider.autoDispose<AsyncValue<HomeScreenData>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final foldersAsync = ref.watch(foldersProvider);
  final mappingsAsync = ref.watch(noteFolderMappingsProvider);

  if (notesAsync.hasError) {
    return AsyncError(notesAsync.error!, notesAsync.stackTrace!);
  }
  if (foldersAsync.hasError) {
    return AsyncError(foldersAsync.error!, foldersAsync.stackTrace!);
  }
  if (mappingsAsync.hasError) {
    return AsyncError(mappingsAsync.error!, mappingsAsync.stackTrace!);
  }

  if (notesAsync.hasValue && foldersAsync.hasValue && mappingsAsync.hasValue) {
    return AsyncData(HomeScreenData(
      notes: notesAsync.value!,
      folders: foldersAsync.value!,
      mappings: mappingsAsync.value!,
    ));
  }

  return const AsyncLoading<HomeScreenData>();
});
