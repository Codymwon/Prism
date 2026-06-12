import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/utils/utils.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

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

      test('should ignore tags inside inline and fenced code blocks', () {
        final content = 'Do not extract `#inlinecode` or \n```\n#fencedcode\n```\nbut extract #validtag.';
        expect(extractTags(content), equals(['validtag']));
      });

      test('should extract nested tags with forward slashes', () {
        expect(extractTags('Logging today in #journal/gratitude/morning.'), equals(['journal/gratitude/morning']));
        expect(extractTags('This note has #tag/subtag/subsubtag.'), equals(['tag/subtag/subsubtag']));
        expect(extractTags('Invalid nested tag ending with slash #tag/'), equals(['tag']));
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

      test('should ignore unclosed double-brackets and not group across lines or other double brackets', () {
        final content = 'Try typing two brackets `[[` followed by the name of another note. For example:\n- Read the [[Productivity Tools Guide]].';
        expect(extractWikilinks(content), equals(['Productivity Tools Guide']));
      });

      test('should ignore wikilinks inside inline and fenced code blocks', () {
        final content = 'Do not extract `[[Inline Code Link]]` or \n```\n[[Fenced Code Link]]\n```\nbut extract [[Valid Link]].';
        expect(extractWikilinks(content), equals(['Valid Link']));
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

      test('should handle unclosed double brackets correctly without processing them', () {
        final text = 'Try typing two brackets `[[` followed by the name of another note. For example:\n- Read the [[Productivity Tools Guide]].';
        expect(
          processWikilinks(text),
          equals('Try typing two brackets `[[` followed by the name of another note. For example:\n- Read the [Productivity Tools Guide](wikilink:Productivity%20Tools%20Guide).'),
        );
      });

      test('should not process wikilinks inside inline and fenced code blocks', () {
        final text = 'Do not change `[[Inline Code Link]]` or \n```\n[[Fenced Code Link]]\n```\nbut process [[Valid Link]].';
        expect(
          processWikilinks(text),
          equals('Do not change `[[Inline Code Link]]` or \n```\n[[Fenced Code Link]]\n```\nbut process [Valid Link](wikilink:Valid%20Link).'),
        );
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

    group('seedWelcomeNotes', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('prism_test_vault');
        SharedPreferences.setMockInitialValues({});
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should seed welcome notes on first launch and set welcomeNotesSeeded to true', () async {
        final prefs = await SharedPreferences.getInstance();
        final vaultKey = 'welcomeNotesSeeded_${tempDir.path.hashCode}';
        expect(prefs.getBool(vaultKey), isNull);

        await seedWelcomeNotes(tempDir.path);

        final welcomeFile = File(p.join(tempDir.path, 'Welcome to Prism.md'));
        final guideFile = File(p.join(tempDir.path, 'Productivity Tools Guide.md'));

        expect(await welcomeFile.exists(), isTrue);
        expect(await guideFile.exists(), isTrue);
        expect(prefs.getBool(vaultKey), isTrue);
      });

      test('should not seed welcome notes again if welcomeNotesSeeded is true', () async {
        final prefs = await SharedPreferences.getInstance();
        final vaultKey = 'welcomeNotesSeeded_${tempDir.path.hashCode}';
        await prefs.setBool(vaultKey, true);

        await seedWelcomeNotes(tempDir.path);

        final welcomeFile = File(p.join(tempDir.path, 'Welcome to Prism.md'));
        final guideFile = File(p.join(tempDir.path, 'Productivity Tools Guide.md'));

        expect(await welcomeFile.exists(), isFalse);
        expect(await guideFile.exists(), isFalse);
      });
    });

    group('extractChecklist', () {
      test('should extract checkable checklist items', () {
        const content = 'Some text\n- [ ] Task 1\n- [x] Task 2\nOther text';
        final result = extractChecklist(content);
        expect(result.length, equals(2));
        expect(result[0].label, equals('Task 1'));
        expect(result[0].isChecked, isFalse);
        expect(result[1].label, equals('Task 2'));
        expect(result[1].isChecked, isTrue);
      });

      test('should ignore checklist items in YAML frontmatter', () {
        const content = '---\ntitle: "Note"\ndescription: " - [ ] not a task"\n---\n- [ ] Real Task';
        final result = extractChecklist(content);
        expect(result.length, equals(1));
        expect(result[0].label, equals('Real Task'));
      });

      test('should ignore checklist items in fenced code blocks', () {
        const content = '```\n- [ ] Code task\n```\n- [ ] Real Task';
        final result = extractChecklist(content);
        expect(result.length, equals(1));
        expect(result[0].label, equals('Real Task'));
      });
    });

    group('extractPreviewImage', () {
      test('should extract first image preview path', () {
        const content = 'Some text\n![alt text](attachments/pic.png)\n![alt 2](pic2.png)';
        expect(extractPreviewImage(content), equals('attachments/pic.png'));
      });

      test('should ignore image tags inside fenced code blocks', () {
        const content = '```\n![code](code.png)\n```\n![real](real.png)';
        expect(extractPreviewImage(content), equals('real.png'));
      });
    });

  });
}

