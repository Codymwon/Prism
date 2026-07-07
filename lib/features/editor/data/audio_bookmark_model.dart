import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_bookmark_model.freezed.dart';

/// Model representing a timestamp bookmark on an audio note.
@freezed
class AudioBookmark with _$AudioBookmark {
  const AudioBookmark._();

  const factory AudioBookmark({
    required String id,
    required String noteId,
    required String attachmentPath,
    required int timestampMs,
    required String annotationText,
    required DateTime createdAt,
  }) = _AudioBookmark;

  factory AudioBookmark.fromMap(Map<String, dynamic> map) {
    int safeInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return AudioBookmark(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      attachmentPath: map['attachment_path'] as String,
      timestampMs: safeInt(map['timestamp_ms']),
      annotationText: map['annotation_text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(safeInt(map['created_at'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'attachment_path': attachmentPath,
      'timestamp_ms': timestampMs,
      'annotation_text': annotationText,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'AudioBookmark(id: $id, noteId: $noteId, timestampMs: $timestampMs, annotationText: $annotationText)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioBookmark && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
