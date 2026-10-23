import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../../../shared/widgets/prism_toast.dart';
import '../../../../shared/widgets/quick_capture_bottom_sheet.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../settings/presentation/providers/startup_actions.dart';
import 'package:prism/l10n/l10n.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final route = await checkAndRunStartupActions(ref.read);
      if (route != null && mounted) {
        context.push(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pre-warm available vaults list cache without triggering full-screen rebuilds
    ref.listen(availableVaultsProvider, (_, _) {});

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
                  child: Text(context.l10n.notes_list_screen_error(e.toString()), style: TextStyle(color: colorScheme.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    tooltip: context.l10n.notes_list_screen_new_folder_tooltip,
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
                    : (isSearching ? context.l10n.notes_list_screen_search_results_title : context.l10n.notes_list_screen_recent_notes_title),
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
                      child: Text(context.l10n.notes_list_screen_error(e.toString()), style: TextStyle(color: colorScheme.error)),
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
        tooltip: context.l10n.notes_list_screen_all_notes_tooltip,
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
        return context.l10n.notes_list_screen_all_notes_title;
      case '__daily__':
        return context.l10n.notes_list_screen_journal_logs_title;
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
              isSearching ? context.l10n.notes_list_screen_no_notes_found_search : context.l10n.notes_list_screen_workspace_awaits_title,
              style: DesignTypography.heading(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? context.l10n.notes_list_screen_search_help_desc
                  : context.l10n.notes_list_screen_create_help_desc,
              style: DesignTypography.body(
                context,
                fontSize: 14,
                color: DesignColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 16),
              TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: () => QuickCapture.show(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        DesignColors.primary(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          DesignColors.primary(context).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: DesignColors.primary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Quick Capture',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DesignColors.primary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Future<void> _deleteNote(BuildContext context, WidgetRef ref, String id) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNoteById(id);
    if (note == null) return;
    String content = '';
    try {
      content = await repo.readNoteContent(id);
    } catch (_) {}

    await repo.deleteNote(id);

    if (context.mounted) {
      PrismToast.show(
        context,
        'Note "${note.title}" deleted',
        icon: Icons.delete_outline_rounded,
        actionText: 'Undo',
        onAction: () async {
          await repo.restoreNote(note, content);
          if (context.mounted) {
            PrismToast.show(
              context,
              'Note restored',
              icon: Icons.restore_rounded,
            );
          }
        },
      );
    }
  }

  String _getFolderHeaderString(String folderId, HomeScreenData data, VirtualFolder? activeFolder) {
    if (folderId == '__folders__') {
      final total = data.folders.length + 3;
      return context.l10n.notes_list_screen_folders_count(total);
    }
    if (folderId == '__all__') {
      final count = data.notes.length;
      return context.l10n.notes_list_screen_all_notes_count(count);
    }
    if (folderId == '__daily__') {
      final count = data.notes.length;
      return context.l10n.notes_list_screen_journal_logs_count(count);
    }
    if (folderId == '__uncategorized__') {
      final count = data.notes.length;
      return context.l10n.notes_list_screen_uncategorized_count(count);
    }
    final name = activeFolder?.name ?? 'Folder';
    final count = activeFolder?.noteCount ?? data.notes.length;
    return context.l10n.notes_list_screen_custom_folder_count(count, name);
  }
}


