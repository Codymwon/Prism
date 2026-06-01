import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../data/note_repository.dart';
import '../providers/notes_providers.dart';
import '../../data/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../folders/data/folder_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/vault_selector_bottom_sheet.dart';
import '../widgets/grouped_notes_list.dart';

enum HomeViewMode { flat, grouped }

final homeViewModeProvider = StateProvider<HomeViewMode>((ref) => HomeViewMode.grouped);

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = ref.watch(searchQueryProvider);

    final notesAsync = query.trim().isEmpty
        ? ref.watch(notesProvider)
        : ref.watch(searchResultsProvider);

    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final foldersAsync = ref.watch(foldersProvider);
    
    VirtualFolder? activeFolder;
    if (selectedFolderId != null) {
      foldersAsync.whenData((list) {
        try {
          activeFolder = list.firstWhere((f) => f.id == selectedFolderId);
        } catch (_) {}
      });
    }

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: _buildAppBar(colorScheme, activeFolder),
      drawer: const FolderDrawer(),
      body: Column(
        children: [
          // Search bar + Sort Row
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 0, DesignSpacing.screenPadding, 8),
            child: Row(
              children: [
                Expanded(
                  child: SearchBarWidget(
                    onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
                    onClear: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      setState(() => _isSearching = false);
                    },
                    onFocused: () => setState(() => _isSearching = true),
                  ),
                ),
                if (!_isSearching) ...[
                  const SizedBox(width: 8),
                  _buildPremiumSortButton(context, colorScheme),
                ],
              ],
            ),
          ),

          // Tag Filter Banner
          if (selectedTag != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 0, DesignSpacing.screenPadding, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.label_outline_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Filtered by tag: #$selectedTag',
                      style: DesignTypography.heading(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.read(selectedTagProvider.notifier).state = null,
                      child: Icon(Icons.close_rounded, size: 16, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),

          // Notes list
          Expanded(
            child: selectedFolderId == null && query.trim().isEmpty && ref.watch(homeViewModeProvider) == HomeViewMode.grouped
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
                      return _buildLoadingSkeleton();
                    },
                    error: (e, s) => Center(
                      child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                    ),
                  )
                : notesAsync.maybeWhen(
                    data: (notes) => _buildNotesList(notes),
                    orElse: () {
                      if (notesAsync.hasValue) {
                        return _buildNotesList(notesAsync.value!);
                      }
                      return _buildLoadingSkeleton();
                    },
                    error: (e, s) => Center(
                      child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, colorScheme),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme, VirtualFolder? activeFolder) {
    // AsyncNotifier — unwrap safely
    final activeVaultName = ref.watch(activeVaultNameProvider).valueOrNull ?? 'My Vault';
    final folderColor = activeFolder?.colorHex.toColor() ?? const Color(0xFF7C6FF7);

    Widget titleWidget = TactileWrapper(
      onTap: () => _showVaultSelectorBottomSheet(context),
      style: TactileFeedbackStyle.standard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'MERIDIAN',
            style: DesignTypography.display(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ).copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: DesignColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DesignColors.border(context),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeFolder != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: folderColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  Icon(DesignIcons.folderOpen, size: 12, color: DesignColors.textSecondary(context)),
                  const SizedBox(width: 4),
                ],
                Text(
                  activeFolder != null ? '$activeVaultName / ${activeFolder.name}' : activeVaultName,
                  style: DesignTypography.heading(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  DesignIcons.arrowDown,
                  size: 14,
                  color: DesignColors.textSecondary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );

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
      title: Center(child: titleWidget),
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

  Future<void> _showVaultSelectorBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSpacing.borderRadiusLarge)),
      ),
      builder: (ctx) => const VaultSelectorBottomSheet(),
    );
  }

  Widget _buildPremiumSortButton(BuildContext context, ColorScheme colorScheme) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () => _showSortBottomSheet(context),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(
            color: DesignColors.border(context),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.swap_vert_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSpacing.borderRadiusLarge)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final activeSort = ref.watch(noteSortProvider);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const DesignSheetDragHandle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Sort Order',
                      style: DesignTypography.heading(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  _buildSortOptionTile(
                    context: context,
                    ref: ref,
                    title: 'Last Updated (Recent)',
                    description: 'Recently edited notes and folders float to the top',
                    icon: Icons.access_time_rounded,
                    value: NoteSort.updated,
                    isActive: activeSort == NoteSort.updated,
                    colorScheme: colorScheme,
                  ),
                  _buildSortOptionTile(
                    context: context,
                    ref: ref,
                    title: 'Date Created',
                    description: 'Newest folders and notes listed first',
                    icon: Icons.calendar_today_rounded,
                    value: NoteSort.created,
                    isActive: activeSort == NoteSort.created,
                    colorScheme: colorScheme,
                  ),
                  _buildSortOptionTile(
                    context: context,
                    ref: ref,
                    title: 'Alphabetical (A–Z)',
                    description: 'Sort notes and folders by name alphabetically',
                    icon: Icons.sort_by_alpha_rounded,
                    value: NoteSort.title,
                    isActive: activeSort == NoteSort.title,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOptionTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String description,
    required IconData icon,
    required NoteSort value,
    required bool isActive,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TactileWrapper(
        style: TactileFeedbackStyle.standard,
        onTap: () {
          ref.read(noteSortProvider.notifier).state = value;
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : DesignColors.surfaceVariant(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? colorScheme.primary : DesignColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: DesignTypography.body(
                        context,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? colorScheme.primary : DesignColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: DesignTypography.details(
                        context,
                        fontSize: 11,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        return NoteCard(
          note: notes[i],
          onTap: () => context.push('/editor/${notes[i].id}'),
          onDelete: () => _deleteNote(notes[i].id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      itemCount: 6,
      itemBuilder: (context, i) => const _SkeletonNoteCard(),
    );
  }

  Widget _buildFAB(BuildContext context, ColorScheme colorScheme) {
    return DesignFloatingActionButton(
      label: 'New Note',
      icon: DesignIcons.add,
      onTap: () => _createNewNote(context),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.elasticOut);
  }

  Future<void> _createNewNote(BuildContext context) async {
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

  Future<void> _deleteNote(String id) async {
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

// ─── Skeleton loading card ────────────────────────────────────────────────────

class _SkeletonNoteCard extends StatelessWidget {
  const _SkeletonNoteCard();

  @override
  Widget build(BuildContext context) {
    final bg = DesignColors.surfaceVariant(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(DesignSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        border: Border.all(
          color: DesignColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 160, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 5),
          Container(height: 10, width: 220, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: bg.withValues(alpha: 0.5));
  }
}
