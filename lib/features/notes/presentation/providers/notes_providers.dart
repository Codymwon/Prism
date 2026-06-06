import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/utils.dart';
import '../../data/note_model.dart';
import '../../data/note_repository.dart';
import '../../../graph/data/graph_models.dart';
import '../../../graph/data/spatial_group_repository.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_repository.dart';
import '../../../folders/data/folder_model.dart';

// ─── Notes List Providers ─────────────────────────────────────────────────────

/// On wide (desktop) windows the notes list and the editor sit side-by-side.
/// This provider holds the id of the note currently open in the desktop pane.
/// It is completely ignored on mobile — navigation there still uses GoRouter pushes.
final activeDesktopNoteIdProvider = StateProvider<String?>((ref) => null);

final noteSortProvider = StateProvider<NoteSort>((ref) => NoteSort.updated);

final selectedTagProvider = StateProvider<String?>((ref) => null);

final notesProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  await ref.watch(databaseProvider.future);
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
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getUniqueTags();
});

final vaultStatsProvider = FutureProvider.autoDispose<({int totalNotes, int totalWords, int totalLinks})>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getVaultStats();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchFocusProvider = StateProvider<bool>((ref) => false);

final searchResultsProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
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
});

final autocompleteSuggestionsProvider = FutureProvider.autoDispose.family<List<Note>, String>((ref, query) async {
  await ref.watch(databaseProvider.future);
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
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNoteById(id);
});

final backlinksProvider = FutureProvider.autoDispose.family<List<Backlink>, String>((ref, noteId) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getBacklinks(noteId);
});

final graphDataProvider = FutureProvider.autoDispose<({
  List<GraphNode> nodes,
  List<GraphEdge> edges,
  List<SpatialGroup> spatialGroups,
  Map<String, String> nodeToGroup,
  Map<String, List<String>> groupNodes,
})>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  ref.watch(foldersVersionProvider);
  ref.watch(spatialGroupsVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  final groupRepo = ref.watch(spatialGroupRepositoryProvider);
  
  final data = await repo.getGraphData();
  final Map<String, GraphNodePosition> pinnedCoords = await repo.getPinnedCoordinates();

  final updatedNodes = data.nodes.map((node) {
    final pinned = pinnedCoords[node.id];
    if (pinned != null) {
      return node.copyWith(
        isPinned: true,
        pinnedX: pinned.x,
        pinnedY: pinned.y,
      );
    }
    return node;
  }).toList();

  final groups = await groupRepo.getAllSpatialGroups();
  final mappings = await groupRepo.getSpatialGroupNodeMappings();
  
  final Map<String, String> nodeToGroup = {};
  final Map<String, List<String>> groupNodes = {};

  for (final entry in mappings.entries) {
    final groupId = entry.key;
    final noteIds = entry.value;
    groupNodes[groupId] = noteIds;
    for (final noteId in noteIds) {
      nodeToGroup[noteId] = groupId;
    }
  }

  return (
    nodes: updatedNodes,
    edges: data.edges,
    spatialGroups: groups,
    nodeToGroup: nodeToGroup,
    groupNodes: groupNodes,
  );
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

final noteDetailsProvider = FutureProvider.autoDispose.family<({List<String> tags, String snippet}), Note>((ref, note) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  final repo = ref.watch(noteRepositoryProvider);
  
  // 1. Get tags
  final tags = await repo.getTagsForNote(note.id);
  
  // 2. Read first few lines of the file as snippet
  String snippet = '';
  try {
    final content = await repo.readNoteContent(note.id);
    snippet = _getCleanSnippet(content);
  } catch (e) {
    debugPrint('Error reading note snippet: $e');
  }
  
  return (tags: tags, snippet: snippet);
});

String _getCleanSnippet(String content) {
  // 1. Remove title header (usually # Title)
  var clean = content.replaceFirst(RegExp(r'^#\s+.*$', multiLine: true), '');
  // 2. Remove other markdown formatting
  clean = clean.replaceAll(RegExp(r'#+\s+'), ''); // headings
  clean = clean.replaceAll(RegExp(r'\*\*|\*|__|_|`'), ''); // bold, italic, code
  clean = clean.replaceAllMapped(RegExp(r'\[\[(.*?)\]\]'), (match) => match[1] ?? ''); // wikilinks: remove brackets
  clean = clean.replaceAllMapped(RegExp(r'\[(.*?)\]\((.*?)\)'), (match) => match[1] ?? ''); // standard links
  clean = clean.replaceAll(RegExp(r'#\w+'), ''); // inline tags
  
  // Clean up whitespace
  clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  // Take first 100 characters
  if (clean.length > 100) {
    return '${clean.substring(0, 97)}...';
  }
  return clean;
}

// ─── Daily Journal Log & Streak Providers ─────────────────────────────────────

final allDailyDatesProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  
  final db = await ref.watch(databaseProvider.future);
  final maps = await db.query(
    'notes',
    columns: ['daily_date'],
    where: 'is_daily = 1 AND is_ghost = 0',
  );
  final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  return maps
      .map((m) => m['daily_date'] as String?)
      .where((d) => d != null && d.isNotEmpty && datePattern.hasMatch(d))
      .cast<String>()
      .toSet();
});

final journalStreakProvider = FutureProvider.autoDispose<({int streak, int totalCount})>((ref) async {
  final datesSet = await ref.watch(allDailyDatesProvider.future);
  if (datesSet.isEmpty) {
    return (streak: 0, totalCount: 0);
  }

  // Compute current consecutive writing streak
  int streak = 0;
  DateTime checkDate = DateTime.now();
  String checkStr = formatDailyDate(checkDate);

  // If no entry for today, check starting from yesterday to allow today's entry to be pending
  if (!datesSet.contains(checkStr)) {
    checkDate = checkDate.subtract(const Duration(days: 1));
    checkStr = formatDailyDate(checkDate);
  }

  while (datesSet.contains(checkStr)) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
    checkStr = formatDailyDate(checkDate);
  }

  return (streak: streak, totalCount: datesSet.length);
});

// ─── Daily Note Content Provider (family by date string) ──────────────────────
// Properly named family provider — avoids the inline FutureProvider anti-pattern
// which creates a new provider instance on every build() call causing flicker.
final dailyNoteProvider = FutureProvider.autoDispose.family<({Note note, String content})?, String>((ref, dateStr) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);

  final repo = ref.watch(noteRepositoryProvider);
  final note = await repo.getDailyNote(dateStr);
  if (note == null) return null;

  String content = '';
  try {
    content = await repo.readNoteContent(note.id);
  } catch (_) {}

  return (note: note, content: content);
});
