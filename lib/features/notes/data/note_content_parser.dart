class NoteMetadata {
  final String title;
  final String body;
  final int wordCount;
  final List<String> tags;
  final List<String> wikilinks;
  final Map<String, String> wikilinkContexts;
  final String snippet;

  NoteMetadata({
    required this.title,
    this.body = '',
    required this.wordCount,
    required this.tags,
    required this.wikilinks,
    required this.wikilinkContexts,
    required this.snippet,
  });
}

abstract class NoteContentParser {
  NoteMetadata parse(String content);
  String titleToSlug(String title);
  String snippet(String content);
}
