/// Sorting order for retrieving notes from the database.
enum NoteSort { updated, created, title }

/// Note model representing a single .md file entry in the SQLite index.
class Note {
  final String id;
  final String title;
  final String filePath;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGhost;
  final bool isDaily;
  final String? dailyDate;
  final bool isConflicted;
  final String? originalNoteId;

  const Note({
    required this.id,
    required this.title,
    required this.filePath,
    required this.wordCount,
    required this.createdAt,
    required this.updatedAt,
    this.isGhost = false,
    this.isDaily = false,
    this.dailyDate,
    this.isConflicted = false,
    this.originalNoteId,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      wordCount: map['word_count'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isGhost: (map['is_ghost'] as int? ?? 0) == 1,
      isDaily: (map['is_daily'] as int? ?? 0) == 1,
      dailyDate: map['daily_date'] as String?,
      isConflicted: (map['is_conflicted'] as int? ?? 0) == 1,
      originalNoteId: map['original_note_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'word_count': wordCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_ghost': isGhost ? 1 : 0,
      'is_daily': isDaily ? 1 : 0,
      'daily_date': dailyDate,
      'is_conflicted': isConflicted ? 1 : 0,
      'original_note_id': originalNoteId,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? filePath,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isGhost,
    bool? isDaily,
    String? dailyDate,
    bool? isConflicted,
    String? originalNoteId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isGhost: isGhost ?? this.isGhost,
      isDaily: isDaily ?? this.isDaily,
      dailyDate: dailyDate ?? this.dailyDate,
      isConflicted: isConflicted ?? this.isConflicted,
      originalNoteId: originalNoteId ?? this.originalNoteId,
    );
  }

  @override
  String toString() => 'Note(id: $id, title: $title, isGhost: $isGhost, isConflicted: $isConflicted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Note && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A single backlink reference — which note links to this one and a snippet.
class Backlink {
  final String sourceId;
  final String sourceTitle;
  final String? contextSnippet;

  const Backlink({
    required this.sourceId,
    required this.sourceTitle,
    this.contextSnippet,
  });
}

/// A graph node for the Graph View visualization.
class GraphNode {
  final String id;
  final String title;
  final int linkCount;
  final String? colorHex; // from folder membership

  const GraphNode({
    required this.id,
    required this.title,
    required this.linkCount,
    this.colorHex,
  });
}

/// A graph edge between two notes (for Graph View).
class GraphEdge {
  final String sourceId;
  final String targetId;

  const GraphEdge({required this.sourceId, required this.targetId});
}
