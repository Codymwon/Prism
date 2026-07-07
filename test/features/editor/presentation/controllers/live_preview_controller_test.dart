import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/controllers/live_preview_controller.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';

void main() {
  // We need a BuildContext to build TextSpans because they look up DesignColors.
  // We can use testWidgets to get a BuildContext.
  group('LivePreviewController Tests', () {
    testWidgets('should render cursor line as raw text with dimmed syntax', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final controller = LivePreviewController(
                noteId: 'test-note-id',
                mode: EditorMode.livePreview,
              );

              // Set text with heading on line 1, and bold on line 2
              controller.text = '### Heading\nThis is **bold**';
              
              // Place cursor on line 1 (Heading)
              controller.selection = const TextSelection.collapsed(offset: 5); // inside 'Heading'

              final span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                withComposing: false,
              );

              // Since cursor is on line 1, the '###' should be present and styled with textTertiary (dimmed)
              // Let's inspect the span tree.
              // We'll write a helper to traverse the span tree and verify styles.
              expect(span, isA<TextSpan>());
              final textSpan = span;
              expect(textSpan.children, isNotNull);

              // Line 1 spans (cursor line): should have '###' as a span
              final spans = _flattenSpans(textSpan);
              final hashSpan = spans.firstWhere((s) => s.text == '###');
              expect(hashSpan.style?.color, isNotNull); // Should have tertiary color

              // Line 2 spans (non-cursor line): should have 'bold' as a bold span, and '**' should be hidden (zero font size)
              final boldSpan = spans.firstWhere((s) => s.text == 'bold');
              expect(boldSpan.style?.fontWeight, FontWeight.bold);

              final boldSyntaxSpans = spans.where((s) => s.text == '**').toList();
              for (final syntaxSpan in boldSyntaxSpans) {
                expect(syntaxSpan.style?.fontSize, 0); // Hidden
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ));
    });

    testWidgets('should render all lines as raw with dimmed syntax in source mode', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final controller = LivePreviewController(
                noteId: 'test-note-id',
                mode: EditorMode.source,
              );

              controller.text = '### Heading\nThis is **bold**';
              
              // Place cursor on line 1, but since we are in source mode, line 2 should also be raw
              controller.selection = const TextSelection.collapsed(offset: 5);

              final span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                withComposing: false,
              );

              final spans = _flattenSpans(span);

              // Line 1: '###' is dimmed
              final hashSpan = spans.firstWhere((s) => s.text == '###');
              expect(hashSpan.style?.color, isNotNull);

              // Line 2 (non-cursor line but source mode): '**' should be visible and dimmed, NOT hidden
              final boldSyntaxSpans = spans.where((s) => s.text == '**').toList();
              expect(boldSyntaxSpans.length, 2);
              for (final syntaxSpan in boldSyntaxSpans) {
                expect(syntaxSpan.style?.fontSize, isNot(0)); // NOT hidden
                expect(syntaxSpan.style?.color, isNotNull); // Dimmed
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ));
    });

    testWidgets('should render hashtag with custom background and color in live preview mode', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final controller = LivePreviewController(
                noteId: 'test-note-id',
                mode: EditorMode.livePreview,
              );

              // Set text with a hashtag
              controller.text = 'This is a #tag';
              // Cursor is far away at index 0 (not on the hashtag line)
              controller.selection = const TextSelection.collapsed(offset: 0);

              final span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                withComposing: false,
              );

              final spans = _flattenSpans(span);
              final tagSpan = spans.firstWhere((s) => s.text == '#tag');

              // Hashtag text should be bold, primary color, and have a background highlight
              expect(tagSpan.style?.fontWeight, FontWeight.bold);
              expect(tagSpan.style?.color, isNotNull);
              expect(tagSpan.style?.backgroundColor, isNotNull);

              return const SizedBox.shrink();
            },
          ),
        ),
      ));
    });

    testWidgets('should omit heading hashes and separating spaces on non-cursor lines in live preview mode', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final controller = LivePreviewController(
                noteId: 'test-note-id',
                mode: EditorMode.livePreview,
              );

              controller.text = '### Heading Three';
              // Cursor is at the end of the line, but wait: if there's only one line, that line is always the cursor line!
              // So let's make it two lines, and place cursor on line 2.
              controller.text = '### Heading Three\nLine Two';
              controller.selection = const TextSelection.collapsed(offset: 20); // inside 'Line Two'

              final span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                withComposing: false,
              );

              final spans = _flattenSpans(span);

              // Verification:
              // The hashes '###' and separating space ' ' should NOT be in the flattened spans at all,
              // or should be completely skipped. Only 'Heading Three' and 'Line Two' should be present.
              final hasHashes = spans.any((s) => s.text == '###');
              final hasSpace = spans.any((s) => s.text == ' ');
              final hasHeadingTitle = spans.any((s) => s.text == 'Heading Three');

              expect(hasHashes, isFalse, reason: 'hashes should be omitted');
              expect(hasSpace, isFalse, reason: 'separating space should be omitted');
              expect(hasHeadingTitle, isTrue, reason: 'heading title should be rendered');

              return const SizedBox.shrink();
            },
          ),
        ),
      ));
    });
  });
}

List<TextSpan> _flattenSpans(TextSpan span) {
  final result = <TextSpan>[];
  void visit(InlineSpan s) {
    if (s is TextSpan) {
      if (s.text != null && s.text!.isNotEmpty) {
        result.add(s);
      }
      if (s.children != null) {
        for (final child in s.children!) {
          visit(child);
        }
      }
    }
  }
  visit(span);
  return result;
}
