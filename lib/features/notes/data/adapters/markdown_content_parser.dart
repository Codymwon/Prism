import '../../../../core/utils/utils.dart' as utils;
import '../note_content_parser.dart';

class MarkdownContentParser implements NoteContentParser {
  @override
  NoteMetadata parse(String content) {
    final title = utils.extractTitle(content);
    var cleanContent = utils.stripFrontmatter(content);

    // Strip the H1 header or first non-empty line from the body if it matches the title
    final lines = cleanContent.split('\n');
    int titleIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      // Check if it's the H1 header representing the title
      if (trimmed.startsWith('# ')) {
        final cleanText = trimmed.substring(2).trim();
        if (cleanText == title) {
          titleIndex = i;
          break;
        }
      }

      // Check if the line matches the title exactly (first non-empty line fallback)
      if (trimmed == title) {
        titleIndex = i;
        break;
      }

      break;
    }
    if (titleIndex != -1) {
      lines.removeAt(titleIndex);
      cleanContent = lines.join('\n');
    }

    final wordCount = utils.countWords(cleanContent);
    final tags = utils.extractTags(cleanContent);
    final wikilinks = utils.extractWikilinks(cleanContent);
    final snippetText = snippet(content);
    
    final Map<String, String> wikilinkContexts = {};
    for (final link in wikilinks) {
      final snippet = utils.getWikilinkContext(content, link);
      if (snippet != null) {
        wikilinkContexts[link] = snippet;
      }
    }

    return NoteMetadata(
      title: title,
      wordCount: wordCount,
      tags: tags,
      wikilinks: wikilinks,
      wikilinkContexts: wikilinkContexts,
      snippet: snippetText,
    );
  }

  @override
  String snippet(String content) {
    // 1. Strip frontmatter
    var clean = utils.stripFrontmatter(content);

    // 2. Strip heading lines (starting with `# `)
    clean = clean.replaceAll(RegExp(r'^#+\s+.*$', multiLine: true), '');

    // 3. Strip markdown formatting (**, *, __, _, `)
    clean = clean.replaceAll(RegExp(r'\*\*|\*|__|_|`'), '');

    // 4. Strip wikilinks brackets (preserving the text inside)
    clean = clean.replaceAllMapped(RegExp(r'\[\[([^\[\]\r\n]+)\]\]'), (match) => match[1] ?? '');

    // 5. Strip standard link markdown (preserving the label)
    clean = clean.replaceAllMapped(RegExp(r'\[([^\[\]\r\n]+)\]\(([^)]+)\)'), (match) => match[1] ?? '');

    // 6. Strip inline tags
    clean = clean.replaceAll(RegExp(r'#\w+'), '');

    // 7. Clean up multiple spaces and newlines
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 8. Truncate if longer than 200 characters
    if (clean.length > 200) {
      clean = '${clean.substring(0, 197)}...';
    }

    return clean;
  }

  @override
  String titleToSlug(String title) {
    return utils.titleToSlug(title);
  }
}
