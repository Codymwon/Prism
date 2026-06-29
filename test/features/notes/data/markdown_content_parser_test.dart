import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/core/utils/utils.dart';

void main() {
  group('MarkdownContentParser tests', () {
    final parser = MarkdownContentParser();

    test('should not parse wikilinks or tags in the H1 title header', () {
      const content = '''# Welcome to [[Prism]] #tutorial
This is the body of the note containing [[AnotherNote]] and #validtag.''';

      final metadata = parser.parse(content);

      expect(metadata.title, equals('Welcome to [[Prism]] #tutorial'));
      expect(metadata.wikilinks, isNot(contains('Prism')));
      expect(metadata.wikilinks, contains('AnotherNote'));
      expect(metadata.tags, isNot(contains('tutorial')));
      expect(metadata.tags, contains('validtag'));
    });

    test('should not parse wikilinks or tags in the first non-empty line fallback title', () {
      const content = '''[[Prism]] Fallback #tutorial
This is the body of the note containing [[AnotherNote]] and #validtag.''';

      final metadata = parser.parse(content);

      expect(metadata.title, equals('[[Prism]] Fallback #tutorial'));
      expect(metadata.wikilinks, isNot(contains('Prism')));
      expect(metadata.wikilinks, contains('AnotherNote'));
      expect(metadata.tags, isNot(contains('tutorial')));
      expect(metadata.tags, contains('validtag'));
    });

    test('should behave correctly when title is in frontmatter', () {
      const content = '''---
title: Welcome to [[Prism]] #tutorial
---
This is the body of the note containing [[AnotherNote]] and #validtag.''';

      final metadata = parser.parse(content);

      expect(metadata.title, equals('Welcome to [[Prism]] #tutorial'));
      expect(metadata.wikilinks, isNot(contains('Prism')));
      expect(metadata.wikilinks, contains('AnotherNote'));
      expect(metadata.tags, isNot(contains('tutorial')));
      expect(metadata.tags, contains('validtag'));
    });

    test('should ignore tags and wikilinks inside code blocks and HTML comments', () {
      const content = '''# Test Title
This is a [[RealLink]] and a #realtag.
```dart
#faketag
[[FakeLink]]
```
<!-- #commenttag -->
<!-- [[CommentLink]] -->
`#inlinecode` and `[[InlineLink]]`''';

      final metadata = parser.parse(content);

      expect(metadata.wikilinks, contains('RealLink'));
      expect(metadata.wikilinks, isNot(contains('FakeLink')));
      expect(metadata.wikilinks, isNot(contains('CommentLink')));
      expect(metadata.wikilinks, isNot(contains('InlineLink')));

      expect(metadata.tags, contains('realtag'));
      expect(metadata.tags, isNot(contains('faketag')));
      expect(metadata.tags, isNot(contains('commenttag')));
      expect(metadata.tags, isNot(contains('inlinecode')));
    });

  });
}
