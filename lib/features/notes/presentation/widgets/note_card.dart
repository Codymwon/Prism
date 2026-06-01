import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSpacing.borderRadiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignSheetDragHandle(),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: Text('Open', style: DesignTypography.body(context)),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(DesignIcons.folderOpen),
              title: Text('Organize', style: DesignTypography.body(context)),
              onTap: () {
                Navigator.pop(ctx);
                _showFolderAssignDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(DesignIcons.delete, color: Colors.redAccent),
              title: Text(
                'Delete',
                style: DesignTypography.body(context, color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
