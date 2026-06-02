import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../folders/presentation/widgets/folder_icon_display.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../data/note_model.dart';
import '../../data/note_repository.dart';
import '../providers/notes_providers.dart';
import 'note_card.dart';
import 'grouped_empty_state.dart';

class GroupedNotesList extends ConsumerStatefulWidget {
  final List<Note> allNotes;
  final List<VirtualFolder> folders;
  final Map<String, List<String>> mappings;
  /// If provided, tapping a note calls this instead of pushing a GoRouter route.
  /// Used by the desktop split-pane to open the note in the right-hand editor.
  final void Function(String noteId)? onNoteTap;

  const GroupedNotesList({
    super.key,
    required this.allNotes,
    required this.folders,
    required this.mappings,
    this.onNoteTap,
  });

  @override
  ConsumerState<GroupedNotesList> createState() => _GroupedNotesListState();
}

class _GroupedNotesListState extends ConsumerState<GroupedNotesList> {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final sort = ref.watch(noteSortProvider);

    // 1. Single-pass pre-grouping: O(N) instead of O(F * N)
    final folderToNotes = <String, List<Note>>{};
    final journalNotes = <Note>[];
    final uncategorizedNotes = <Note>[];

    for (final note in widget.allNotes) {
      if (note.isDaily) {
        journalNotes.add(note);
      } else {
        final folderIds = widget.mappings[note.id];
        if (folderIds == null || folderIds.isEmpty) {
          uncategorizedNotes.add(note);
        } else {
          for (final fid in folderIds) {
            folderToNotes.putIfAbsent(fid, () => []).add(note);
          }
        }
      }
    }

    // 2. Sort folders using pre-grouped, fast O(1) map lookups
    final sortedFolders = List<VirtualFolder>.from(widget.folders);
    if (sort == NoteSort.title) {
      sortedFolders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sort == NoteSort.updated) {
      sortedFolders.sort((a, b) {
        final aNotes = folderToNotes[a.id] ?? const [];
        final bNotes = folderToNotes[b.id] ?? const [];

        if (aNotes.isEmpty && bNotes.isEmpty) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (aNotes.isEmpty) return 1;
        if (bNotes.isEmpty) return -1;

        // O(1) retrieval since notes lists are already sorted in notesProvider
        return bNotes.first.updatedAt.compareTo(aNotes.first.updatedAt);
      });
    } else if (sort == NoteSort.created) {
      sortedFolders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (widget.folders.isEmpty && journalNotes.isEmpty && uncategorizedNotes.isEmpty) {
      return const GroupedEmptyState();
    }

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
            iconKey: 'auto_stories',
            storageKey: 'system-journals',
          ),

        // B. Custom Virtual Folders
        ...sortedFolders.map((folder) {
          final folderColor = folder.colorHex.toColor();
          // O(1) lookup instead of full list scan
          final folderNotes = folderToNotes[folder.id] ?? const [];

          return _buildAccordionCard(
            context: context,
            title: folder.name,
            notes: folderNotes,
            folderColor: folderColor,
            iconKey: folder.icon,
            storageKey: 'folder-${folder.id}',
            folderId: folder.id,
            folder: folder,
          );
        }),

        // C. Uncategorized Notes System Folder (only if there are uncategorized notes)
        if (uncategorizedNotes.isNotEmpty)
          _buildAccordionCard(
            context: context,
            title: 'Uncategorized Notes',
            notes: uncategorizedNotes,
            folderColor: DesignColors.textSecondary(context),
            iconKey: 'inbox',
            storageKey: 'system-uncategorized',
          ),

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
    required String iconKey,
    required String storageKey,
    String? folderId,
    VirtualFolder? folder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final themeColor = colorScheme.primary;

    return GestureDetector(
      onLongPress: folder != null ? () => FolderDrawer.showFolderOptions(context, ref, folder) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
          border: Border.all(
            color: themeColor.withValues(alpha: isDark ? 0.2 : 0.3),
            width: 0.8,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            key: PageStorageKey(storageKey),
            leading: FolderIconDisplay(
              iconKey: iconKey,
              color: folderColor,
              size: 32,
              badgeSize: folder != null ? 8 : 0,
              useThemedIcon: true,
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
                      color: themeColor,
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
                    color: themeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notes.length}',
                    style: DesignTypography.mono(
                      fontSize: 10,
                      color: themeColor,
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
            children: [
              _AccordionNotesList(
                notes: notes,
                onDelete: _deleteNote,
                onNoteTap: widget.onNoteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _AccordionNotesList extends StatelessWidget {
  final List<Note> notes;
  final Function(String) onDelete;
  final void Function(String noteId)? onNoteTap;

  const _AccordionNotesList({
    required this.notes,
    required this.onDelete,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          'No notes in this category.',
          style: DesignTypography.body(
            context,
            fontSize: 12,
            color: DesignColors.textSecondary(context),
          ).copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use a recessed background so note cards visually "sit inside" the folder.
    // Dark: surfaceVariant gives the right depth. Light: a very faint neutral overlay.
    final cardBg = isDark
        ? DesignColors.surfaceVariant(context)
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.03),
            DesignColors.surface(context),
          );

    return Column(
      children: notes.map((note) {
        return NoteCard(
          note: note,
          backgroundColor: cardBg,
          onTap: onNoteTap != null
              ? () => onNoteTap!(note.id)
              : () => context.push('/editor/${note.id}'),
          onDelete: () => onDelete(note.id),
        );
      }).toList(),
    );
  }
}
