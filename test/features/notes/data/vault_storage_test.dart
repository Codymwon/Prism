import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:meridian/features/notes/data/adapters/local_vault_storage.dart';
import 'package:meridian/features/notes/data/adapters/markdown_content_parser.dart';

void main() {
  late Directory tempDir;
  late LocalVaultStorage storage;
  late MarkdownContentParser parser;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('meridian_storage_test');
    storage = LocalVaultStorage();
    parser = MarkdownContentParser();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalVaultStorage Tests', () {
    test('should write and read file content', () async {
      final filePath = p.join(tempDir.path, 'note1.md');
      await storage.writeContent(filePath, 'Hello World');
      
      final exists = await storage.exists(filePath);
      expect(exists, isTrue);

      final content = await storage.readContent(filePath);
      expect(content, equals('Hello World'));
    });

    test('should delete file content', () async {
      final filePath = p.join(tempDir.path, 'note1.md');
      await storage.writeContent(filePath, 'Hello World');
      await storage.deleteContent(filePath);

      final exists = await storage.exists(filePath);
      expect(exists, isFalse);
    });

    test('should list markdown files in vault', () async {
      final file1 = p.join(tempDir.path, 'note1.md');
      final file2 = p.join(tempDir.path, 'note2.md');
      final file3 = p.join(tempDir.path, 'image.png'); // non-markdown

      await storage.writeContent(file1, 'Note 1');
      await storage.writeContent(file2, 'Note 2');
      // Create binary/dummy file directly
      await File(file3).writeAsBytes([0, 1, 2]);

      final files = await storage.listDocumentIdentifiers(tempDir.path);
      expect(files.length, equals(2));
      expect(files, contains(file1));
      expect(files, contains(file2));
      expect(files, isNot(contains(file3)));
    });
  });

  group('MarkdownContentParser Tests', () {
    test('should parse title, tags, and wikilinks correctly', () {
      const content = '''# My Awesome Note

This is some content with #productivity and #tutorial tags.
I am linking to [[Productivity Tools Guide]] and [[Welcome to Meridian]].
      ''';

      final metadata = parser.parse(content);
      expect(metadata.title, equals('My Awesome Note'));
      expect(metadata.wordCount, equals(24)); // 24 words in text
      expect(metadata.tags, containsAll(['productivity', 'tutorial']));
      expect(metadata.wikilinks, containsAll(['Productivity Tools Guide', 'Welcome to Meridian']));
    });

    test('should slugify title correctly', () {
      expect(parser.titleToSlug('My New Note!'), equals('my-new-note'));
    });
  });
}
