import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../data/note_model.dart';
import 'note_card.dart';

class NotesBentoGrid extends StatelessWidget {
  final List<Note> notes;
  final void Function(String noteId)? onNoteTap;
  final void Function(String noteId) onDelete;

  const NotesBentoGrid({
    super.key,
    required this.notes,
    this.onNoteTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 8, DesignSpacing.screenPadding, 100),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? width : width / 2,
        mainAxisExtent: 136,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        return NoteCard(
          note: note,
          onTap: onNoteTap != null
              ? () => onNoteTap!(note.id)
              : () => context.push('/editor/${note.id}'),
          onDelete: () => onDelete(note.id),
        );
      },
    );
  }
}
