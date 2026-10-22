import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/island_menu.dart';
import '../../data/note_model.dart';
import '../../../folders/presentation/widgets/folder_assign_dialog.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color? backgroundColor;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DesignNoteCard(
      note: note,
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      backgroundColor: backgroundColor,
    );
  }

  void _showContextMenu(BuildContext context) {
    IslandMenu.show(
      context,
      title: note.title.isEmpty ? 'Untitled' : note.title,
      icon: Icons.article_outlined,
      items: [
        IslandMenuItem(
          label: 'Open',
          icon: Icons.open_in_new_rounded,
          onTap: onTap,
        ),
        IslandMenuItem(
          label: 'Organize',
          icon: DesignIcons.folderOpen,
          onTap: () => _showFolderAssignDialog(context),
        ),
        IslandMenuItem(
          label: 'Delete',
          icon: DesignIcons.delete,
          isDestructive: true,
          onTap: onDelete,
        ),
      ],
    );
  }

  void _showFolderAssignDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FolderAssignDialog(noteId: note.id),
    );
  }
}
