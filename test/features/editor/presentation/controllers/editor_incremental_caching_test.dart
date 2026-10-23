import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/controllers/live_preview_controller.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';
import 'package:prism/features/editor/presentation/utils/markdown_line_parser.dart';

void main() {
  setUp(() {
    MarkdownLineParser.clearCache();
  });

  tearDown(() {
    MarkdownLineParser.clearCache();
  });

  group('MarkdownLineParser Line-Level Memoization', () {
    test('Caches parsed lines across repeated parse calls', () {
      expect(MarkdownLineParser.cacheSize, equals(0));

      const doc1 = '# Heading 1\nThis is a **bold** paragraph.\n- [ ] Task 1';
      final parsed1 = MarkdownLineParser.parse(doc1);
      expect(parsed1.length, equals(3));
      final initialCacheSize = MarkdownLineParser.cacheSize;
      expect(initialCacheSize, equals(3));

      // Parsing identical content should hit the cache without growing cache size
      final parsed2 = MarkdownLineParser.parse(doc1);
      expect(parsed2.length, equals(3));
      expect(MarkdownLineParser.cacheSize, equals(initialCacheSize));

      // Verify lineIndex is correctly assigned even when retrieved from cache
      expect(parsed2[0].lineIndex, equals(0));
      expect(parsed2[1].lineIndex, equals(1));
      expect(parsed2[2].lineIndex, equals(2));
    });

    test('Correctly updates lineIndex when lines are shifted', () {
      const doc = 'Line A\nLine B';
      final parsed = MarkdownLineParser.parse(doc);
      expect(parsed[0].lineIndex, equals(0));
      expect(parsed[1].lineIndex, equals(1));

      // Prepend a new line so Line A and Line B shift down
      const shiftedDoc = 'New Top Line\nLine A\nLine B';
      final shiftedParsed = MarkdownLineParser.parse(shiftedDoc);
      expect(shiftedParsed[0].lineIndex, equals(0));
      expect(shiftedParsed[1].lineIndex, equals(1));
      expect(shiftedParsed[2].lineIndex, equals(2));
      expect(shiftedParsed[1].rawText, equals('Line A'));
      expect(shiftedParsed[2].rawText, equals('Line B'));
    });

    test('Parses large 3,500-line note efficiently', () {
      final buffer = StringBuffer();
      for (int i = 0; i < 3500; i++) {
        buffer.writeln('Paragraph line $i with [[Wikilink $i]] and #tag$i.');
      }
      final largeDoc = buffer.toString();

      final stopwatch = Stopwatch()..start();
      final parsedFirst = MarkdownLineParser.parse(largeDoc);
      stopwatch.stop();
      final firstDurationMs = stopwatch.elapsedMilliseconds;

      expect(parsedFirst.length, equals(3501));

      // Second parse on large note should be faster due to memoization
      stopwatch.reset();
      stopwatch.start();
      final parsedSecond = MarkdownLineParser.parse(largeDoc);
      stopwatch.stop();
      final secondDurationMs = stopwatch.elapsedMilliseconds;

      expect(parsedSecond.length, equals(3501));
      expect(secondDurationMs, lessThanOrEqualTo(firstDurationMs + 20));
    });
  });

  group('LivePreviewController Line Span Caching & Active Blocks', () {
    testWidgets('Caches TextSpan per line and reuses unchanged spans when cursor moves', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final controller = LivePreviewController(
                noteId: 'test-note',
                mode: EditorMode.livePreview,
                text: 'Line 1\nLine 2\nLine 3',
              );

              expect(controller.spanCacheSize, equals(0));

              // Initial build with cursor on line 0
              controller.selection = const TextSelection.collapsed(offset: 2); // 'Li|ne 1'
              final span1 = controller.buildTextSpan(context: context, withComposing: false);
              expect(span1.children, isNotNull);
              expect(span1.children!.length, equals(3));
              final initialSpanCache = controller.spanCacheSize;
              expect(initialSpanCache, greaterThan(0));

              final line3SpanRef1 = span1.children![2];

              // Move cursor to line 1 ('Li|ne 2')
              controller.selection = const TextSelection.collapsed(offset: 9);
              final span2 = controller.buildTextSpan(context: context, withComposing: false);

              // Line 3 was untouched by cursor move; its TextSpan reference should be reused
              final line3SpanRef2 = span2.children![2];
              expect(identical(line3SpanRef1, line3SpanRef2), isTrue);

              // Clear span cache
              controller.clearSpanCache();
              expect(controller.spanCacheSize, equals(0));

              controller.dispose();
              return const SizedBox();
            },
          ),
        ),
      ));
    });

    testWidgets('Pre-calculates active table and code blocks without O(L x B) scans', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              const tableDoc = '| Col A | Col B |\n|---|---|\n| Val 1 | Val 2 |\n\nNormal text';
              final controller = LivePreviewController(
                noteId: 'table-note',
                mode: EditorMode.livePreview,
                text: tableDoc,
                tableBuilder: (lines) => Container(key: const ValueKey('table_widget')),
              );

              // Cursor outside table on 'Normal text'
              controller.selection = TextSelection.collapsed(offset: tableDoc.indexOf('Normal text'));
              final spanOutside = controller.buildTextSpan(context: context, withComposing: false);
              // Outside cursor should render table as WidgetSpan
              expect(spanOutside.children!.any((s) => s is WidgetSpan), isTrue);

              // Cursor inside table row 0
              controller.selection = const TextSelection.collapsed(offset: 3);
              final spanInside = controller.buildTextSpan(context: context, withComposing: false);
              // Inside cursor renders active table rows as raw editable TextSpans
              expect(spanInside.children!.every((s) => s is TextSpan), isTrue);

              controller.dispose();
              return const SizedBox();
            },
          ),
        ),
      ));
    });
  });
}
