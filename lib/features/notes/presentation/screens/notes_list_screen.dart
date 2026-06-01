import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../data/note_repository.dart';
import '../../data/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import '../../../folders/data/folder_repository.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/database/database_helper.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      appBar: _buildAppBar(isDark, colorScheme, activeFolder),
      drawer: const FolderDrawer(),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
          if (!_isSearching) _buildSortChips(isDark, colorScheme),

          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final viewMode = ref.watch(homeViewModeProvider);
                if (selectedFolderId == null && query.trim().isEmpty && viewMode == HomeViewMode.grouped) {
                  final foldersAsync = ref.watch(foldersProvider);
                  final mappingsAsync = ref.watch(noteFolderMappingsProvider);

                  return foldersAsync.when(
                    data: (folders) {
                      return mappingsAsync.when(
                        data: (mappings) => _buildGroupedNotesList(notes, folders, mappings, isDark),
                        loading: () => _buildLoadingSkeleton(isDark),
                        error: (e, s) => Center(child: Text('Error loading mappings: $e')),
                      );
                    },
                    loading: () => _buildLoadingSkeleton(isDark),
                    error: (e, s) => Center(child: Text('Error loading folders: $e')),
                  );
                }
                return _buildNotesList(notes, isDark);
              },
              loading: () => _buildLoadingSkeleton(isDark),
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

  PreferredSizeWidget _buildAppBar(bool isDark, ColorScheme colorScheme, VirtualFolder? activeFolder) {
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
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
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
                  Icon(Icons.folder_open_outlined, size: 12, color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
                  const SizedBox(width: 4),
                ],
                Text(
                  activeFolder != null ? '$activeVaultName / ${activeFolder.name}' : activeVaultName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open drawer',
        ),
      ),
      title: Center(child: titleWidget),
      centerTitle: true,
      actions: [
        if (activeFolder == null) ...[
          IconButton(
            icon: Icon(
              ref.watch(homeViewModeProvider) == HomeViewMode.grouped
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final baseDir = ref.read(baseVaultsDirectoryProvider);
    final activeVault = ref.read(activeVaultNameProvider);

    List<String> vaults = [];
    try {
      final dir = Directory(baseDir);
      if (dir.existsSync()) {
        vaults = dir.listSync()
            .whereType<Directory>()
            .map((d) => p.basename(d.path))
            .where((name) => !name.startsWith('.'))
            .toList();
      }
    } catch (e) {
      debugPrint('Error reading vaults: $e');
    }

    if (vaults.isEmpty) {
      vaults.add(activeVault);
    }

    // Sort alphabetically
    vaults.sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Switch Vault',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
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
                        Icons.folder_rounded,
                        color: isActive ? colorScheme.primary : (isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
                      ),
                      title: Text(
                        vaultName,
                        style: GoogleFonts.inter(
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                        ),
                      ),
                      trailing: isActive ? Icon(Icons.check_rounded, color: colorScheme.primary) : null,
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
                leading: Icon(Icons.add_rounded, color: colorScheme.primary),
                title: Text(
                  'Create New Vault',
                  style: GoogleFonts.inter(
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
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Close current DB helper connection
      await DatabaseHelper.instance.closeDatabase();

      // 2. Set new active vault name provider (this saves to SharedPreferences)
      await ref.read(activeVaultNameProvider.notifier).setVaultName(vaultName);

      if (!mounted) return;

      // 3. Invalidate providers
      ref.read(selectedFolderIdProvider.notifier).state = null;
      ref.invalidate(notesProvider);
      ref.invalidate(foldersProvider);

      // Dismiss loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to vault: $vaultName')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching vault: $e')),
      );
    }
  }

  void _showCreateVaultDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
          title: Text(
            'Create New Vault',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(color: isDark ? MeridianColors.darkText : MeridianColors.lightText),
            decoration: InputDecoration(
              hintText: 'Vault Name',
              hintStyle: GoogleFonts.inter(color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary),
              filled: true,
              fillColor: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await _createNewVault(name);
              },
              child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
      final newVaultPath = p.join(baseDir, vaultName);
      final dir = Directory(newVaultPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Close current DB helper connection
      await DatabaseHelper.instance.closeDatabase();

      // Set new active vault
      await ref.read(activeVaultNameProvider.notifier).setVaultName(vaultName);

      // Initialize with a welcome note since it's a completely empty vault
      final repo = ref.read(noteRepositoryProvider);
      await repo.createNote(
        title: 'Welcome to your new Vault',
        initialContent: '# Welcome to $vaultName\n\nThis is a brand new workspace. Start linking notes using `[[wikilinks]]`!',
      );

      if (!mounted) return;

      // Invalidate providers
      ref.read(selectedFolderIdProvider.notifier).state = null;
      ref.invalidate(notesProvider);
      ref.invalidate(foldersProvider);

      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created and switched to vault: $vaultName')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating vault: $e')),
      );
    }
  }

  Widget _buildSortChips(bool isDark, ColorScheme colorScheme) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : (isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {},
                backgroundColor: isDark
                    ? MeridianColors.darkSurfaceVariant
                    : MeridianColors.lightSurfaceVariant,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : (isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder),
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

  Widget _buildNotesList(List<Note> notes, bool isDark) {
    if (notes.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
    bool isDark,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // A. Journal Logs System Folder (only if there are journal notes)
        if (journalNotes.isNotEmpty)
          _buildAccordionCard(
            context: context,
            title: 'Journal Logs',
            notes: journalNotes,
            folderColor: primaryColor,
            folderIcon: Icons.edit_calendar_rounded,
            storageKey: 'system-journals',
            isDark: isDark,
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
            folderIcon: Icons.folder_rounded,
            storageKey: 'folder-${folder.id}',
            isDark: isDark,
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
            folderColor: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
            folderIcon: Icons.category_rounded,
            storageKey: 'system-uncategorized',
            isDark: isDark,
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
              icon: Icon(Icons.create_new_folder_outlined, size: 18, color: colorScheme.primary),
              label: Text(
                'Create New Folder',
                style: GoogleFonts.inter(
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
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.03),
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
    required bool isDark,
    String? folderId,
    VirtualFolder? folder,
  }) {
    return GestureDetector(
      onLongPress: folder != null ? () => FolderDrawer.showFolderOptions(context, ref, folder) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
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
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
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
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: folderColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
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

  Widget _buildEmptyState(bool isDark) {
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.note_add_outlined,
              size: 64,
              color: isDark
                  ? MeridianColors.darkTextTertiary
                  : MeridianColors.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No notes found' : 'Your workspace awaits',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Tap + to create your first note',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? MeridianColors.darkTextSecondary
                    : MeridianColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 6,
      itemBuilder: (context, i) => _SkeletonNoteCard(isDark: isDark),
    );
  }

  Widget _buildFAB(BuildContext context, ColorScheme colorScheme) {
    return TactileWrapper(
      style: TactileFeedbackStyle.highImpact,
      onTap: () => _createNewNote(context),
      child: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Note',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
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
        title: const Text('Delete note?'),
        content: const Text('This will permanently delete the note and its file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(noteRepositoryProvider).deleteNote(id);
      ref.invalidate(notesProvider);
    }
  }
}

// ─── Skeleton loading card ────────────────────────────────────────────────────

class _SkeletonNoteCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonNoteCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
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
