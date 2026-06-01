import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../data/note_model.dart';
import '../../data/note_repository.dart';
import 'note_card.dart';
import 'grouped_empty_state.dart';

class GroupedNotesList extends ConsumerStatefulWidget {
  final List<Note> allNotes;
  final List<VirtualFolder> folders;
  final Map<String, List<String>> mappings;

  const GroupedNotesList({
    super.key,
    required this.allNotes,
    required this.folders,
    required this.mappings,
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

    // 1. Group Journal notes
    final journalNotes = widget.allNotes.where((n) => n.isDaily).toList();

    // 2. Group Uncategorized notes (non-daily and not in any virtual folder)
    final uncategorizedNotes = widget.allNotes
        .where((n) => !n.isDaily && (widget.mappings[n.id] == null || widget.mappings[n.id]!.isEmpty))
        .toList();

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
            folderIcon: DesignIcons.journal,
            storageKey: 'system-journals',
          ),

        // B. Custom Virtual Folders
        ...widget.folders.map((folder) {
          final folderColor = folder.colorHex.toColor();

          final folderNotes = widget.allNotes
               .where((n) => !n.isDaily && (widget.mappings[n.id]?.contains(folder.id) ?? false))
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
          );
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
            children: [
              _AccordionNotesList(
                notes: notes,
                onDelete: _deleteNote,
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

  const _AccordionNotesList({
    required this.notes,
    required this.onDelete,
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

    return Column(
      children: notes.map((note) {
        return NoteCard(
          note: note,
          onTap: () => context.push('/editor/${note.id}'),
          onDelete: () => onDelete(note.id),
        );
      }).toList(),
    );
  }
}
