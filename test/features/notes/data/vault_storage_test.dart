import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/features/notes/data/adapters/local_vault_storage.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';

void main() {
  late Directory tempDir;
  late LocalVaultStorage storage;
  late MarkdownContentParser parser;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_storage_test');
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
I am linking to [[Productivity Tools Guide]] and [[Welcome to Prism]].
      ''';

      final metadata = parser.parse(content);
      expect(metadata.title, equals('My Awesome Note'));
      expect(metadata.wordCount, equals(20)); // 20 words in text (title line excluded)
      expect(metadata.tags, containsAll(['productivity', 'tutorial']));
      expect(metadata.wikilinks, containsAll(['Productivity Tools Guide', 'Welcome to Prism']));
    });

    test('should parse metadata cleanly with frontmatter', () {
      const content = '''---
title: "Custom Frontmatter Title"
date: 2026-06-04
tags: [ignored]
---
# Main Heading
This is a note with #actualtag and [[Target Link]].
''';
      final metadata = parser.parse(content);
      expect(metadata.title, equals('Custom Frontmatter Title'));
      expect(metadata.tags, contains('actualtag'));
      expect(metadata.tags, isNot(contains('ignored')));
      expect(metadata.wikilinks, contains('Target Link'));
      expect(metadata.wordCount, equals(12));
    });

    test('should slugify title correctly', () {
      expect(parser.titleToSlug('My New Note!'), equals('my-new-note'));
    });
  });
}
