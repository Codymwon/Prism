import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../data/note_repository.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_card.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../widgets/virtual_folders_bento_row.dart';
import '../widgets/notes_bento_grid.dart';

// Extracted Widgets
import '../widgets/skeleton_note_list.dart';
import '../widgets/tag_filter_banner.dart';
import '../widgets/notes_list_search_bar.dart';
import '../../../../core/services/vault_service.dart';



class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-warm available vaults list cache so the selector bottom sheet loads instantly
    ref.watch(availableVaultsProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final selectedFolderId = ref.watch(selectedFolderIdProvider);

    VirtualFolder? activeFolder;
    if (selectedFolderId != null) {
      ref.watch(foldersProvider).whenData((list) {
        try {
          activeFolder = list.firstWhere((f) => f.id == selectedFolderId);
        } catch (_) {}
      });
    }

    final homeDataAsync = ref.watch(homeScreenDataProvider);

    return Listener(
      onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: DesignColors.background(context),
        appBar: _buildAppBar(context, ref, colorScheme, activeFolder),
        drawer: const FolderDrawer(),
        body: BackButtonListener(
          onBackButtonPressed: () async {
            if (selectedFolderId != null) {
              ref.read(selectedFolderIdProvider.notifier).state = null;
              return true; // consumed
            }
            return false; // not consumed
          },
          child: Column(
          children: [
            const NotesListSearchBar(),
            const TagFilterBanner(),

          homeDataAsync.maybeWhen(
            data: (data) => _buildHomeContent(context, ref, data, colorScheme),
            orElse: () {
              if (homeDataAsync.hasValue) {
                return _buildHomeContent(context, ref, homeDataAsync.value!, colorScheme);
              }
              return const Expanded(child: SkeletonNoteList());
            },
            error: (e, s) => Center(
              child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
            ),
          ),
        ],
      ),
    ),),);
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    HomeScreenData data,
    ColorScheme colorScheme,
  ) {
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.trim().isNotEmpty;
    final folderActive = selectedFolderId != null;

    final activeFolder = data.folders.cast<VirtualFolder?>().firstWhere(
      (f) => f?.id == selectedFolderId,
      orElse: () => null,
    );

    return Expanded(
      child: Column(
        children: [
          if (!isSearching && !folderActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOLDERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.12,
                      color: DesignColors.textSecondary(context),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: DesignColors.textSecondary(context),
                    ),
                    onPressed: () => FolderDrawer.navigateToAddFolderScreen(context),
                    tooltip: 'New Folder',
                  ),
                ],
              ),
            ),
            VirtualFoldersBentoRow(
              allNotes: data.notes,
              folders: data.folders,
              mappings: data.mappings,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                folderActive
                    ? _getFolderHeaderString(selectedFolderId, data, activeFolder)
                    : (isSearching ? 'SEARCH RESULTS' : 'RECENT NOTES'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                if (selectedFolderId == '__folders__') {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    child: VirtualFoldersBentoRow(
                      allNotes: data.notes,
                      folders: data.folders,
                      mappings: data.mappings,
                      showAll: true,
                    ),
                  );
                }
                if (isSearching) {
                  final searchAsync = ref.watch(searchResultsProvider);
                  return searchAsync.maybeWhen(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return _buildEmptyState(context, ref);
                      }
                      return NotesBentoGrid(
                        notes: notes,
                        onDelete: (id) => _deleteNote(context, ref, id),
                      );
                    },
                    orElse: () => const SkeletonNoteList(),
                  );
                }

                if (!folderActive) {
                  final recentAsync = ref.watch(recentNotesProvider);
                  return recentAsync.maybeWhen(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return _buildEmptyState(context, ref);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: notes.length,
                        itemBuilder: (context, i) {
                          final note = notes[i];
                          return NoteCard(
                            note: note,
                            onTap: () => context.push('/editor/${note.id}'),
                            onDelete: () => _deleteNote(context, ref, note.id),
                          );
                        },
                      );
                    },
                    orElse: () {
                      if (recentAsync.hasValue) {
                        final notes = recentAsync.value!;
                        if (notes.isEmpty) {
                          return _buildEmptyState(context, ref);
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: notes.length,
                          itemBuilder: (context, i) {
                            final note = notes[i];
                            return NoteCard(
                              note: note,
                              onTap: () => context.push('/editor/${note.id}'),
                              onDelete: () => _deleteNote(context, ref, note.id),
                            );
                          },
                        );
                      }
                      return const SkeletonNoteList();
                    },
                  );
                } else {
                  final notesAsync = ref.watch(notesProvider);
                  return notesAsync.maybeWhen(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return _buildEmptyState(context, ref);
                      }
                      return NotesBentoGrid(
                        notes: notes,
                        onDelete: (id) => _deleteNote(context, ref, id),
                      );
                    },
                    orElse: () {
                      if (notesAsync.hasValue) {
                        final notes = notesAsync.value!;
                        if (notes.isEmpty) {
                          return _buildEmptyState(context, ref);
                        }
                        return NotesBentoGrid(
                          notes: notes,
                          onDelete: (id) => _deleteNote(context, ref, id),
                        );
                      }
                      return const SkeletonNoteList();
                    },
                    error: (e, s) => Center(
                      child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }



  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    VirtualFolder? activeFolder,
  ) {
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    if (selectedFolderId == null) {
      return null;
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(DesignIcons.back),
        onPressed: () {
          ref.read(selectedFolderIdProvider.notifier).state = null;
        },
        tooltip: 'All Notes',
      ),
      title: Text(
        _getAppBarTitle(selectedFolderId, activeFolder),
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: DesignColors.text(context),
          letterSpacing: 0.2,
        ),
      ),
      centerTitle: false,
      backgroundColor: DesignColors.background(context),
      actions: const [],
    );
  }

  String _getAppBarTitle(String? folderId, VirtualFolder? activeFolder) {
    if (folderId == null) return 'PRISM';
    if (activeFolder != null) return activeFolder.name;
    switch (folderId) {
      case '__all__':
        return 'All Notes';
      case '__daily__':
        return 'Journal Logs';
      case '__uncategorized__':
        return 'Uncategorized';
      case '__folders__':
        return 'Folders';
      default:
        return 'Notes';
    }
  }


  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? DesignIcons.searchOff : Icons.note_add_outlined,
              size: 64,
              color: DesignColors.textTertiary(context),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No notes found' : 'Your workspace awaits',
              style: DesignTypography.heading(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Tap + to create your first note',
              style: DesignTypography.body(
                context,
                fontSize: 14,
                color: DesignColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }



  Future<void> _deleteNote(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete note?', style: DesignTypography.heading(context, fontWeight: FontWeight.bold)),
        content: Text('This will permanently delete the note and its file.', style: DesignTypography.body(context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: DesignTypography.details(context))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: DesignTypography.details(context, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(noteRepositoryProvider).deleteNote(id);
    }
  }

  String _getFolderHeaderString(String folderId, HomeScreenData data, VirtualFolder? activeFolder) {
    if (folderId == '__folders__') {
      final total = data.folders.length + 3;
      return 'Folders • $total folder${total == 1 ? "" : "s"}';
    }
    if (folderId == '__all__') {
      final count = data.notes.length;
      return 'All Notes • $count note${count == 1 ? "" : "s"}';
    }
    if (folderId == '__daily__') {
      final count = data.notes.length;
      return 'Journal Logs • $count note${count == 1 ? "" : "s"}';
    }
    if (folderId == '__uncategorized__') {
      final count = data.notes.length;
      return 'Uncategorized • $count note${count == 1 ? "" : "s"}';
    }
    final name = activeFolder?.name ?? 'Folder';
    final count = activeFolder?.noteCount ?? data.notes.length;
    return '$name • $count note${count == 1 ? "" : "s"}';
  }
}



