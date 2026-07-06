import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/note_model.dart';
import '../../data/note_repository.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_repository.dart';
import '../../../folders/data/folder_model.dart';
import '../../../onboarding/data/onboarding_provider.dart';

part 'notes_providers.g.dart';

// ─── Notes List Providers ─────────────────────────────────────────────────────


@riverpod
class NoteSortNotifier extends _$NoteSortNotifier {
  @override
  NoteSort build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index = prefs.getInt('note_sort_preference');
    if (index != null && index >= 0 && index < NoteSort.values.length) {
      return NoteSort.values[index];
    }
    return NoteSort.updated;
  }

  @override
  NoteSort get state => super.state;

  @override
  set state(NoteSort value) {
    super.state = value;
    _save(value);
  }

  Future<void> _save(NoteSort value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('note_sort_preference', value.index);
  }
}

@riverpod
class SelectedTag extends _$SelectedTag {
  @override
  String? build() => null;

  @override
  String? get state => super.state;

  @override
  set state(String? value) => super.state = value;
}

@riverpod
Future<List<Note>> notes(NotesRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  ref.watch(foldersVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  final sort = ref.watch(noteSortNotifierProvider);
  
  final tag = ref.watch(selectedTagProvider);
  if (tag != null) {
    return repo.getNotesByTag(tag);
  }
  
  final folderId = ref.watch(selectedFolderIdProvider);
  if (folderId != null) {
    if (folderId == '__all__') {
      final all = await repo.getAllNotes(sort: sort);
      return all.where((n) => !n.isDaily).toList();
    }
    if (folderId == '__daily__') {
      final all = await repo.getAllNotes(sort: sort);
      return all.where((n) => n.isDaily).toList();
    }
    if (folderId == '__uncategorized__') {
      final all = await repo.getAllNotes(sort: sort);
      final mappings = await ref.watch(noteFolderMappingsProvider.future);
      return all.where((n) => !n.isDaily && (mappings[n.id] == null || mappings[n.id]!.isEmpty)).toList();
    }
    final folderRepo = ref.watch(folderRepositoryProvider);
    return folderRepo.getNotesInFolder(folderId, sort: sort);
  }
  
  final all = await repo.getAllNotes(sort: sort);
  return all.where((n) => !n.isDaily).toList();
}

@riverpod
Future<List<Note>> recentNotes(RecentNotesRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  final all = await repo.getAllNotes(sort: NoteSort.updated);
  return all.where((n) => !n.isGhost).take(5).toList();
}

@riverpod
Future<List<String>> uniqueTags(UniqueTagsRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getUniqueTags();
}

@riverpod
Future<({int totalNotes, int totalWords, int totalLinks})> vaultStats(VaultStatsRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getVaultStats();
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  @override
  String get state => super.state;

  @override
  set state(String value) => super.state = value;
}

@riverpod
class SearchFocus extends _$SearchFocus {
  @override
  bool build() => false;

  @override
  bool get state => super.state;

  @override
  set state(bool value) => super.state = value;
}

@riverpod
Future<List<Note>> searchResults(SearchResultsRef ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(noteRepositoryProvider);
  if (query.trim().isEmpty) return [];
  
  bool didDispose = false;
  ref.onDispose(() => didDispose = true);
  
  await Future.delayed(const Duration(milliseconds: 250));
  if (didDispose) return [];
  
  return repo.searchNotes(query);
}

@riverpod
Future<List<Note>> autocompleteSuggestions(AutocompleteSuggestionsRef ref, String query) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  if (query.trim().isEmpty) return [];
  
  bool didDispose = false;
  ref.onDispose(() => didDispose = true);
  
  await Future.delayed(const Duration(milliseconds: 150));
  if (didDispose) return [];
  
  return repo.getTitleSuggestions(query);
}

@riverpod
Future<Note?> noteById(NoteByIdRef ref, String id) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNoteById(id);
}

@riverpod
Future<List<Backlink>> backlinks(BacklinksRef ref, String noteId) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getBacklinks(noteId);
}

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

@riverpod
AsyncValue<HomeScreenData> homeScreenData(HomeScreenDataRef ref) {
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
}

@riverpod
Future<({List<String> tags, String snippet})> noteDetails(NoteDetailsRef ref, String noteId) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  
  final note = await repo.getNoteById(noteId);
  final snippet = note?.snippet ?? '';
  final tags = await repo.getTagsForNote(noteId);
  
  return (tags: tags, snippet: snippet);
}
