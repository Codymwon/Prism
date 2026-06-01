import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/services/vault_service.dart';
import '../../data/note_repository.dart';
import '../providers/notes_providers.dart';
import '../../data/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

enum HomeViewMode { flat, grouped }

final homeViewModeProvider = StateProvider<HomeViewMode>((ref) => HomeViewMode.flat);

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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 0, DesignSpacing.screenPadding, 8),
            child: SearchBarWidget(
              onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
              onClear: () {
                ref.read(searchQueryProvider.notifier).state = '';
                setState(() => _isSearching = false);
              },
              onFocused: () => setState(() => _isSearching = true),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

          // Sort chips (only shown when not searching)
          if (!_isSearching) _buildSortChips(colorScheme),

          // Notes list
          Expanded(
            child: selectedFolderId == null && query.trim().isEmpty && ref.watch(homeViewModeProvider) == HomeViewMode.grouped
                ? ref.watch(homeScreenDataProvider).when(
                    data: (data) => _buildGroupedNotesList(data.notes, data.folders, data.mappings),
                    loading: () => _buildLoadingSkeleton(),
                    error: (e, s) => Center(
                      child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
                    ),
                  )
                : notesAsync.when(
                    data: (notes) => _buildNotesList(notes),
                    loading: () => _buildLoadingSkeleton(),
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
    final activeVaultName = ref.watch(activeVaultNameProvider);
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
      leading: Builder(
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
        ],
      ],
    );
  }

  Future<void> _showVaultSelectorBottomSheet(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final baseDir = ref.read(baseVaultsDirectoryProvider);
    final activeVault = ref.read(activeVaultNameProvider);

    final vaults = ref.read(vaultServiceProvider).getAvailableVaults(baseDir, activeVault);

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSpacing.borderRadiusLarge)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const DesignSheetDragHandle(),
              const SizedBox(height: 8),
              Text(
                'Switch Vault',
                style: DesignTypography.heading(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vaults.length,
                  itemBuilder: (c, idx) {
                    final vaultName = vaults[idx];
                    final isActive = vaultName == activeVault;

                    return ListTile(
                      leading: Icon(
                        DesignIcons.folder,
                        color: isActive ? colorScheme.primary : DesignColors.textSecondary(context),
                      ),
                      title: Text(
                        vaultName,
                        style: DesignTypography.body(
                          context,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isActive ? Icon(DesignIcons.check, color: colorScheme.primary) : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (!isActive) {
                          await _switchVault(vaultName);
                        }
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(DesignIcons.add, color: colorScheme.primary),
                title: Text(
                  'Create New Vault',
                  style: DesignTypography.heading(
                    context,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateVaultDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchVault(String vaultName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(vaultServiceProvider).switchVault(vaultName: vaultName, ref: ref);

      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to vault: $vaultName', style: DesignTypography.body(context, color: Colors.white))),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching vault: $e', style: DesignTypography.body(context, color: Colors.white))),
      );
    }
  }

  void _showCreateVaultDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: DesignColors.surface(context),
          title: Text(
            'Create New Vault',
            style: DesignTypography.heading(context, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: DesignTypography.body(context),
            decoration: InputDecoration(
              hintText: 'Vault Name',
              hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
              filled: true,
              fillColor: DesignColors.surfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: DesignColors.border(context)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: DesignTypography.details(context)),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await _createNewVault(name);
              },
              child: Text('Create', style: DesignTypography.details(context, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewVault(String vaultName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final baseDir = ref.read(baseVaultsDirectoryProvider);
      await ref.read(vaultServiceProvider).createVault(
        vaultName: vaultName,
        baseDir: baseDir,
        ref: ref,
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created and switched to vault: $vaultName', style: DesignTypography.body(context, color: Colors.white))),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating vault: $e', style: DesignTypography.body(context, color: Colors.white))),
      );
    }
  }

  Widget _buildSortChips(ColorScheme colorScheme) {
    final sort = ref.watch(noteSortProvider);
    final chips = [
      (NoteSort.updated, 'Recent'),
      (NoteSort.created, 'Created'),
      (NoteSort.title, 'A–Z'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.screenPadding),
        children: chips.map((c) {
          final isSelected = sort == c.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TactileWrapper(
              style: TactileFeedbackStyle.standard,
              onTap: () => ref.read(noteSortProvider.notifier).state = c.$1,
              child: FilterChip(
                label: Text(
                  c.$2,
                  style: DesignTypography.heading(
                    context,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : DesignColors.textSecondary(context),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {},
                backgroundColor: DesignColors.surfaceVariant(context),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : DesignColors.border(context),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 250.ms);
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
        ).animate().fadeIn(duration: 100.ms).slideY(begin: 0.02, duration: 100.ms);
      },
    );
  }

  Widget _buildGroupedNotesList(
    List<Note> allNotes,
    List<VirtualFolder> folders,
    Map<String, List<String>> mappings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    // 1. Group Journal notes
    final journalNotes = allNotes.where((n) => n.isDaily).toList();

    // 2. Group Uncategorized notes (non-daily and not in any virtual folder)
    final uncategorizedNotes = allNotes
        .where((n) => !n.isDaily && (mappings[n.id] == null || mappings[n.id]!.isEmpty))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      children: [
        // A. Journal Logs System Folder (only if there are journal notes)
        if (journalNotes.isNotEmpty)
          _buildAccordionCard(
            context: context,
            title: 'Journal Logs',
            notes: journalNotes,
            folderColor: primaryColor,
            folderIcon: DesignIcons.journal,
            storageKey: 'system-journals',
          ).animate().fadeIn(duration: 350.ms),

        // B. Custom Virtual Folders
        ...folders.map((folder) {
          final folderColor = folder.colorHex.toColor();

          final folderNotes = allNotes
               .where((n) => !n.isDaily && (mappings[n.id]?.contains(folder.id) ?? false))
               .toList();

          return _buildAccordionCard(
            context: context,
            title: folder.name,
            notes: folderNotes,
            folderColor: folderColor,
            folderIcon: DesignIcons.folder,
            storageKey: 'folder-${folder.id}',
            folderId: folder.id,
            folder: folder,
          ).animate().fadeIn(duration: 400.ms);
        }),

        // C. Uncategorized Notes System Folder (only if there are uncategorized notes)
        if (uncategorizedNotes.isNotEmpty)
          _buildAccordionCard(
            context: context,
            title: 'Uncategorized Notes',
            notes: uncategorizedNotes,
            folderColor: DesignColors.textSecondary(context),
            folderIcon: Icons.category_rounded,
            storageKey: 'system-uncategorized',
          ).animate().fadeIn(duration: 450.ms),

        // D. Create New Folder quick button
        TactileWrapper(
          style: TactileFeedbackStyle.highImpact,
          onTap: () => FolderDrawer.showAddFolderSheet(context, ref),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24, top: 12),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(DesignIcons.addFolder, size: 18, color: colorScheme.primary),
              label: Text(
                'Create New Folder',
                style: DesignTypography.heading(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
                ),
                backgroundColor: colorScheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.03),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionCard({
    required BuildContext context,
    required String title,
    required List<Note> notes,
    required Color folderColor,
    required IconData folderIcon,
    required String storageKey,
    String? folderId,
    VirtualFolder? folder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: folder != null ? () => FolderDrawer.showFolderOptions(context, ref, folder) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
          border: Border.all(
            color: folderColor.withValues(alpha: isDark ? 0.3 : 0.4),
            width: 0.8,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: folderColor.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(storageKey),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: folderColor.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                folderIcon,
                size: 16,
                color: folderColor,
              ),
            ),
            title: Text(
              title,
              style: DesignTypography.heading(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (folderId != null) ...[
                  TactileWrapper(
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      ref.read(selectedFolderIdProvider.notifier).state = folderId;
                    },
                    child: IconButton(
                      icon: const Icon(DesignIcons.forward, size: 16),
                      color: folderColor,
                      onPressed: () {},
                      tooltip: 'Focus folder',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: folderColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notes.length}',
                    style: DesignTypography.mono(
                      fontSize: 10,
                      color: folderColor,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  DesignIcons.arrowDown,
                  color: DesignColors.textSecondary(context),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            children: notes.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No notes in this category.',
                        style: DesignTypography.body(
                          context,
                          fontSize: 12,
                          color: DesignColors.textSecondary(context),
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]
                : notes.map((note) {
                    return NoteCard(
                      note: note,
                      onTap: () => context.push('/editor/${note.id}'),
                      onDelete: () => _deleteNote(note.id),
                    );
                  }).toList(),
          ),
        ),
      ),
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
