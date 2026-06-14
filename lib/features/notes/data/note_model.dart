import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_model.freezed.dart';

/// Sorting order for retrieving notes from the database.
enum NoteSort { updated, created, title }

/// Note model representing a single .md file entry in the SQLite index.
@freezed
class Note with _$Note {
  const Note._();

  const factory Note({
    required String id,
    required String title,
    required String filePath,
    required int wordCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isGhost,
    @Default(false) bool isDaily,
    String? dailyDate,
    @Default(false) bool isConflicted,
    String? originalNoteId,
    @Default('') String snippet,
  }) = _Note;

  factory Note.fromMap(Map<String, dynamic> map) {
    // sqflite rawQuery JOINs (e.g. getNotesInFolder) can return INTEGER columns
    // as double or bool depending on the Android sqflite version. Use safe helpers
    // for every numeric field to prevent runtime type-cast crashes.
    int safeInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      wordCount: safeInt(map['word_count']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(safeInt(map['created_at'])),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(safeInt(map['updated_at'])),
      isGhost: map['is_ghost'] == 1 || map['is_ghost'] == true,
      isDaily: map['is_daily'] == 1 || map['is_daily'] == true,
      dailyDate: map['daily_date'] as String?,
      isConflicted: map['is_conflicted'] == 1 || map['is_conflicted'] == true,
      originalNoteId: map['original_note_id'] as String?,
      snippet: map['snippet'] as String? ?? '',
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
      'snippet': snippet,
    };
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
@freezed
class Backlink with _$Backlink {
  const factory Backlink({
    required String sourceId,
    required String sourceTitle,
    String? contextSnippet,
  }) = _Backlink;
}


/// A graph node for the Graph View visualization.
class GraphNode {
  final String id;
  final String title;
  final int linkCount;
  final String? colorHex; // from folder membership
  final bool isTemporal;
  final String? temporalType; // 'week', 'month', 'year'
  final bool isGhost;
  final bool isPinned;
  final double? pinnedX;
  final double? pinnedY;

  const GraphNode({
    required this.id,
    required this.title,
    required this.linkCount,
    this.colorHex,
    this.isTemporal = false,
    this.temporalType,
    this.isGhost = false,
    this.isPinned = false,
    this.pinnedX,
    this.pinnedY,
  });

  GraphNode copyWith({
    String? id,
    String? title,
    int? linkCount,
    String? colorHex,
    bool? isTemporal,
    String? temporalType,
    bool? isGhost,
    bool? isPinned,
    double? pinnedX,
    double? pinnedY,
  }) {
    return GraphNode(
      id: id ?? this.id,
      title: title ?? this.title,
      linkCount: linkCount ?? this.linkCount,
      colorHex: colorHex ?? this.colorHex,
      isTemporal: isTemporal ?? this.isTemporal,
      temporalType: temporalType ?? this.temporalType,
      isGhost: isGhost ?? this.isGhost,
      isPinned: isPinned ?? this.isPinned,
      pinnedX: pinnedX ?? this.pinnedX,
      pinnedY: pinnedY ?? this.pinnedY,
    );
  }
}

/// A graph edge between two notes (for Graph View).
class GraphEdge {
  final String sourceId;
  final String targetId;

  const GraphEdge({required this.sourceId, required this.targetId});
}
