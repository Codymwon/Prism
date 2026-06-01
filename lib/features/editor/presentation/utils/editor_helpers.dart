import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../notes/data/note_repository.dart';

/// Standard wikilink tapping navigation helper.
///
/// Looks up or creates target notes from dynamic [[wikilinks]] inside markdown rendering and navigates to them.
Future<void> handleWikilinkTap({
  required String? href,
  required WidgetRef ref,
  required BuildContext context,
}) async {
  if (href != null && href.startsWith('wikilink:')) {
    final encodedTitle = href.substring('wikilink:'.length);
    final targetTitle = Uri.decodeComponent(encodedTitle);
    final repo = ref.read(noteRepositoryProvider);
    var targetNote = await repo.getNoteByTitle(targetTitle);
    targetNote ??= await repo.createNote(title: targetTitle);
    if (context.mounted) {
      context.push('/editor/${targetNote.id}');
    }
  }
}
