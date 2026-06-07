import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/utils/utils.dart';

void main() {
  group('Core Note Utilities Test Suite', () {
    
    group('titleToSlug', () {
      test('should convert uppercase to lowercase', () {
        expect(titleToSlug('My New Note'), equals('my-new-note'));
      });

      test('should strip out special directory characters and punctuation', () {
        expect(titleToSlug('New/Note..With\\Traversals!'), equals('newnotewithtraversals'));
      });

      test('should convert multiple spaces and tabs to single hyphens', () {
        expect(titleToSlug('Note   with \t tabs   and spaces'), equals('note-with-tabs-and-spaces'));
      });

      test('should trim leading and trailing spaces or hyphens', () {
        expect(titleToSlug(' - Note Title - '), equals('-note-title-'));
      });

      test('should keep hyphens and underscores', () {
        expect(titleToSlug('note_with-hyphens_and_underscores'), equals('note_with-hyphens_and_underscores'));
      });
    });

    group('extractTitle', () {
      test('should extract title from frontmatter if present', () {
        expect(extractTitle('---\ntitle: My Frontmatter Title\n---\n# Some H1 Header'), equals('My Frontmatter Title'));
      });

      test('should extract title from standard markdown H1 header if no frontmatter title', () {
        expect(extractTitle('# Welcome to Prism\n\nSome body text.'), equals('Welcome to Prism'));
      });

      test('should trim H1 header title whitespaces', () {
        expect(extractTitle('#    My Custom Title    \nBody.'), equals('My Custom Title'));
      });

      test('should fallback to first non-empty line if no H1 or frontmatter exists', () {
        expect(extractTitle('\n\nFirst line of note\nSecond line.'), equals('First line of note'));
      });

      test('should return "Untitled" if content is completely empty', () {
        expect(extractTitle('   \n\n  '), equals('Untitled'));
      });
    });

    group('Frontmatter Helpers', () {
      test('should strip frontmatter cleanly', () {
        expect(stripFrontmatter('---\ntitle: A\ndate: 2026-06-04\n---\nMy body content'), equals('My body content'));
        expect(stripFrontmatter('No frontmatter content'), equals('No frontmatter content'));
      });

      test('should extract frontmatter values', () {
        final content = '---\ntitle: "My Cool Title"\ndate: 2026-06-04\n---';
        expect(extractFrontmatterValue(content, 'title'), equals('My Cool Title'));
        expect(extractFrontmatterValue(content, 'date'), equals('2026-06-04'));
        expect(extractFrontmatterValue(content, 'nonexistent'), isNull);
      });
    });

    group('countWords', () {
      test('should return 0 for empty or whitespace content', () {
        expect(countWords('   \n\t  '), equals(0));
      });

      test('should count standard words correctly', () {
        expect(countWords('This is a simple note.'), equals(5));
      });

      test('should ignore redundant consecutive spaces', () {
        expect(countWords('Word    consecutive \t spacing'), equals(3));
      });
    });

    group('extractTags', () {
      test('should extract single tags in content', () {
        expect(extractTags('Jotting down some thoughts #productivity.'), equals(['productivity']));
      });

      test('should extract multiple tags and convert to lowercase', () {
        final tags = extractTags('#Ideas for #Productivity and #WORK.');
        expect(tags, equals(['ideas', 'productivity', 'work']));
      });

      test('should ignore numeric hex colors and numbers', () {
        expect(extractTags('The background color is #5C3D2E and number is #123'), isEmpty);
      });

      test('should ignore inline hash symbols without letters', () {
        expect(extractTags('Hash without tag # 123'), isEmpty);
      });
    });

    group('extractWikilinks', () {
      test('should extract single double-bracket wikilinks', () {
        expect(extractWikilinks('Read more in [[Getting Started]].'), equals(['Getting Started']));
      });

      test('should extract multiple wikilinks from a single line', () {
        final links = extractWikilinks('Refer to [[Note A]] and [[Note B]] for details.');
        expect(links, equals(['Note A', 'Note B']));
      });

      test('should ignore standard single brackets', () {
        expect(extractWikilinks('Standard [Markdown link](https://google.com) example.'), isEmpty);
      });
    });

    group('processWikilinks', () {
      test('should map single wikilinks to custom wikilink schema', () {
        final result = processWikilinks('Connecting to [[My Note]].');
        expect(result, equals('Connecting to [My Note](wikilink:My%20Note).'));
      });

      test('should map multiple wikilinks correctly', () {
        final result = processWikilinks('From [[A]] to [[B]].');
        expect(result, equals('From [A](wikilink:A) to [B](wikilink:B).'));
      });

      test('should leave text without wikilinks untouched', () {
        final text = 'Just standard text with [standard link](url).';
        expect(processWikilinks(text), equals(text));
      });
    });

    group('Date Helpers', () {
      test('should format DateTime to YYYY-MM-DD string', () {
        final date = DateTime(2026, 6, 1);
        expect(formatDailyDate(date), equals('2026-06-01'));
      });

      test('should check if date is today', () {
        final todayStr = formatDailyDate(DateTime.now());
        expect(isToday(todayStr), isTrue);
        expect(isToday('2000-01-01'), isFalse);
      });
    });

  });
}
