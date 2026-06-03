class NoteMetadata {
  final String title;
  final int wordCount;
  final List<String> tags;
  final List<String> wikilinks;
  final Map<String, String> wikilinkContexts;

  NoteMetadata({
    required this.title,
    required this.wordCount,
    required this.tags,
    required this.wikilinks,
    required this.wikilinkContexts,
  });
}

abstract class NoteContentParser {
  NoteMetadata parse(String content);
  String titleToSlug(String title);
}
