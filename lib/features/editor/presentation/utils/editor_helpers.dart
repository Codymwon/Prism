import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/data/note_repository.dart';
import '../../../settings/presentation/providers/custom_macro_provider.dart';

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

/// Helper to insert Markdown formatting at the current selection of the text editor.
void insertFormatting({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String prefix,
  String suffix = '',
}) {
  final text = controller.text;
  final selection = controller.selection;
  
  if (!selection.isValid) {
    final newText = text + prefix + suffix;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length - suffix.length),
    );
    return;
  }
  
  final start = selection.start;
  final end = selection.end;
  final selectedText = text.substring(start, end);
  
  final newSelectedText = prefix + selectedText + suffix;
  final newText = text.replaceRange(start, end, newSelectedText);
  
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: start + prefix.length + selectedText.length,
    ),
  );
  
  focusNode.requestFocus();
}

/// Helper to resolve template variables inside a macro and insert the resolved text.
void insertMacro({
  required TextEditingController controller,
  required FocusNode focusNode,
  required CustomMacro macro,
}) {
  final now = DateTime.now();
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final dateStr = '$year-$month-$day';

  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final timeStr = '$hour:$minute';

  final resolvedText = macro.text
      .replaceAll('{{date}}', dateStr)
      .replaceAll('{{time}}', timeStr)
      .replaceAll('{{datetime}}', '$dateStr $timeStr');

  insertFormatting(
    controller: controller,
    focusNode: focusNode,
    prefix: resolvedText,
  );
}

/// Custom Inline Markdown Syntax for Highlights (==text==)
class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'==([^=]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match.group(1)!));
    return true;
  }
}

/// Custom Element Builder to render the custom 'mark' highlight tag
class HighlightElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  HighlightElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: TextStyle(
          backgroundColor: DesignColors.accentAmber(context).withValues(alpha: 0.3),
          color: DesignColors.text(context),
          fontWeight: preferredStyle?.fontWeight,
          fontStyle: preferredStyle?.fontStyle,
        ),
      ),
    );
  }
}
