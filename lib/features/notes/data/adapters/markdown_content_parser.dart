import '../../../../core/utils/utils.dart' as utils;
import '../note_content_parser.dart';

class MarkdownContentParser implements NoteContentParser {
  @override
  NoteMetadata parse(String content) {
    final title = utils.extractTitle(content);
    final wordCount = utils.countWords(content);
    final tags = utils.extractTags(content);
    final wikilinks = utils.extractWikilinks(content);
    
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
