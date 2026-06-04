import '../../../../core/utils/utils.dart' as utils;
import '../note_content_parser.dart';

class MarkdownContentParser implements NoteContentParser {
  @override
  NoteMetadata parse(String content) {
    final title = utils.extractTitle(content);
    final cleanContent = utils.stripFrontmatter(content);
    final wordCount = utils.countWords(cleanContent);
    final tags = utils.extractTags(cleanContent);
    final wikilinks = utils.extractWikilinks(cleanContent);
    
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
    );
  }

  @override
  String titleToSlug(String title) {
    return utils.titleToSlug(title);
  }
}
