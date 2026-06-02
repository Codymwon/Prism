import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../data/note_repository.dart';
import '../providers/notes_providers.dart';
import '../../data/note_model.dart';
import '../widgets/note_card.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../folders/data/folder_repository.dart';
import '../widgets/grouped_notes_list.dart';
import '../../../editor/presentation/screens/editor_screen.dart';

// Extracted Widgets
import '../widgets/skeleton_note_list.dart';
import '../widgets/tag_filter_banner.dart';
import '../widgets/vault_selector_title.dart';
import '../widgets/notes_list_search_bar.dart';
import '../../../../core/services/vault_service.dart';

// Desktop breakpoint — keep in sync with app_shell.dart
const double _kDesktopBreakpoint = 800;

enum HomeViewMode { flat, grouped }

final homeViewModeProvider = StateProvider<HomeViewMode>((ref) => HomeViewMode.grouped);

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-warm available vaults list cache so the selector bottom sheet loads instantly
    ref.watch(availableVaultsProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= _kDesktopBreakpoint;
    final selectedFolderId = ref.watch(selectedFolderIdProvider);

    VirtualFolder? activeFolder;
    if (selectedFolderId != null) {
      ref.watch(foldersProvider).whenData((list) {
        try {
          activeFolder = list.firstWhere((f) => f.id == selectedFolderId);
        } catch (_) {}
      });
    }

    if (isDesktop) {
      return _buildDesktopLayout(context, ref, colorScheme, activeFolder);
    }

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: _buildAppBar(context, ref, colorScheme, activeFolder),
      drawer: const FolderDrawer(),
      body: Column(
        children: [
          const NotesListSearchBar(),
          const TagFilterBanner(),

          // Notes list
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final query = ref.watch(searchQueryProvider);
                final notesAsync = query.trim().isEmpty
                    ? ref.watch(notesProvider)
                    : ref.watch(searchResultsProvider);

                return selectedFolderId == null && query.trim().isEmpty && ref.watch(homeViewModeProvider) == HomeViewMode.grouped
                    ? ref.watch(homeScreenDataProvider).maybeWhen(
                        data: (data) => GroupedNotesList(
                          allNotes: data.notes,
                          folders: data.folders,
                          mappings: data.mappings,
                        ),
                        orElse: () {
                          final data = ref.watch(homeScreenDataProvider).valueOrNull;
                          if (data != null) {
                            return GroupedNotesList(
                              allNotes: data.notes,
                              folders: data.folders,
                              mappings: data.mappings,
                            );
                          }
                          return const SkeletonNoteList();
                        },
                        error: (e, s) => Center(
                          child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                        ),
                      )
                    : notesAsync.maybeWhen(
                        data: (notes) => _buildNotesList(context, ref, notes),
                        orElse: () {
                          if (notesAsync.hasValue) {
                            return _buildNotesList(context, ref, notesAsync.value!);
                          }
                          return const SkeletonNoteList();
                        },
                        error: (e, s) => Center(
                          child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, ref),
    );
  }

  // ─── Desktop two-pane layout ─────────────────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    VirtualFolder? activeFolder,
  ) {
    return Row(
      children: [
        // Left panel: notes list (340px fixed)
        SizedBox(
          width: 340,
          child: Scaffold(
            backgroundColor: DesignColors.background(context),
            appBar: _buildAppBar(context, ref, colorScheme, activeFolder),
            drawer: const FolderDrawer(),
            body: _buildListBody(context, ref, colorScheme),
            floatingActionButton: _buildFAB(context, ref),
          ),
        ),
        // Vertical divider
        Container(
          width: 0.5,
          color: DesignColors.border(context),
        ),
        // Right panel: inline editor or empty state
        const Expanded(
          child: _DesktopEditorPane(),
        ),
      ],
    );
  }

  Widget _buildListBody(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    return Column(
      children: [
        const NotesListSearchBar(),
        const TagFilterBanner(),
        // Notes list
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final query = ref.watch(searchQueryProvider);
              final notesAsync = query.trim().isEmpty
                  ? ref.watch(notesProvider)
                  : ref.watch(searchResultsProvider);

              return selectedFolderId == null && query.trim().isEmpty && ref.watch(homeViewModeProvider) == HomeViewMode.grouped
                  ? ref.watch(homeScreenDataProvider).maybeWhen(
                      data: (data) => GroupedNotesList(
                        allNotes: data.notes,
                        folders: data.folders,
                        mappings: data.mappings,
                        onNoteTap: (id) => ref.read(activeDesktopNoteIdProvider.notifier).state = id,
                      ),
                      orElse: () {
                        final data = ref.watch(homeScreenDataProvider).valueOrNull;
                        if (data != null) {
                          return GroupedNotesList(
                            allNotes: data.notes,
                            folders: data.folders,
                            mappings: data.mappings,
                            onNoteTap: (id) => ref.read(activeDesktopNoteIdProvider.notifier).state = id,
                          );
                        }
                        return const SkeletonNoteList();
                      },
                      error: (e, s) => Center(
                        child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                      ),
                    )
                  : notesAsync.maybeWhen(
                      data: (notes) => _buildDesktopNotesList(context, ref, notes),
                      orElse: () {
                        if (notesAsync.hasValue) {
                          return _buildDesktopNotesList(context, ref, notesAsync.value!);
                        }
                        return const SkeletonNoteList();
                      },
                      error: (e, s) => Center(
                        child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNotesList(BuildContext context, WidgetRef ref, List<Note> notes) {
    if (notes.isEmpty) return _buildEmptyState(context, ref);
    final activeNoteId = ref.watch(activeDesktopNoteIdProvider);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        final isActive = note.id == activeNoteId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          ),
          child: NoteCard(
            note: note,
            onTap: () => ref.read(activeDesktopNoteIdProvider.notifier).state = note.id,
            onDelete: () => _deleteNote(context, ref, note.id),
            backgroundColor: Colors.transparent,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    VirtualFolder? activeFolder,
  ) {
    return AppBar(
      leading: activeFolder != null
          ? IconButton(
              icon: const Icon(DesignIcons.back),
              onPressed: () {
                ref.read(selectedFolderIdProvider.notifier).state = null;
              },
              tooltip: 'All Notes',
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(DesignIcons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Open drawer',
              ),
            ),
      title: const Center(child: VaultSelectorTitle()),
      centerTitle: true,
      backgroundColor: DesignColors.background(context),
      actions: [
        if (activeFolder == null) ...[
          IconButton(
            icon: Icon(
              ref.watch(homeViewModeProvider) == HomeViewMode.grouped
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: DesignColors.textSecondary(context),
            ),
            onPressed: () {
              final current = ref.read(homeViewModeProvider);
              ref.read(homeViewModeProvider.notifier).state =
                  current == HomeViewMode.flat ? HomeViewMode.grouped : HomeViewMode.flat;
            },
            tooltip: ref.watch(homeViewModeProvider) == HomeViewMode.grouped
                ? 'Switch to flat list'
                : 'Switch to folder grouped view',
          ),
          const SizedBox(width: 4),
        ] else
          const SizedBox(width: 48), // Balanced invisible placeholder to keep title centered!
      ],
    );
  }

  Widget _buildNotesList(BuildContext context, WidgetRef ref, List<Note> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        return NoteCard(
          note: notes[i],
          onTap: () => context.push('/editor/${notes[i].id}'),
          onDelete: () => _deleteNote(context, ref, notes[i].id),
        );
      },
    );
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

  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    return DesignFloatingActionButton(
      label: 'New Note',
      icon: DesignIcons.add,
      onTap: () => _createNewNote(context, ref),
    );
  }

  Future<void> _createNewNote(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.createNote();

    // Check if we are currently inside a folder view and associate the new note automatically
    final selectedFolderId = ref.read(selectedFolderIdProvider);
    if (selectedFolderId != null) {
      final folderRepo = ref.read(folderRepositoryProvider);
      await folderRepo.addNoteToFolder(note.id, selectedFolderId);
    }

    if (context.mounted) {
      context.push('/editor/${note.id}?new=true');
    }
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
}

// ─── Desktop Editor Panel (Isolated Rebuild Scope) ────────────────────────────

class _DesktopEditorPane extends ConsumerWidget {
  const _DesktopEditorPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNoteId = ref.watch(activeDesktopNoteIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: activeNoteId != null
          ? KeyedSubtree(
              key: ValueKey(activeNoteId),
              child: EditorScreen(noteId: activeNoteId),
            )
          : _buildDesktopEmptyPane(context, colorScheme),
    );
  }

  Widget _buildDesktopEmptyPane(BuildContext context, ColorScheme colorScheme) {
    return Container(
      key: const ValueKey('empty_pane'),
      color: DesignColors.background(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.article_outlined,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a note to read or edit',
              style: DesignTypography.heading(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DesignColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your note will appear here',
              style: DesignTypography.body(
                context,
                fontSize: 13,
                color: DesignColors.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
