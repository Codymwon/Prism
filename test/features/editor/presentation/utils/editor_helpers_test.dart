import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/editor/presentation/utils/editor_helpers.dart';

class TestImageWidget extends ConsumerWidget {
  final Uri uri;
  final String noteId;

  const TestImageWidget({super.key, required this.uri, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetResult = buildMarkdownImage(
      uri: uri,
      noteId: noteId,
      ref: ref,
      context: context,
    );
    return MaterialApp(
      home: Scaffold(
        body: widgetResult,
      ),
    );
  }
}

void main() {
  group('buildMarkdownImage', () {
    testWidgets('should render a Card with Image.network for remote network images', (WidgetTester tester) async {
      final uri = Uri.parse('https://example.com/image.png');
      await tester.pumpWidget(
        ProviderScope(
          child: TestImageWidget(uri: uri, noteId: 'note-id'),
        ),
      );

      // Should not be empty/SizedBox.shrink
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
