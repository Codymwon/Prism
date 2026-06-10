/// Model representing coordinates and pin state of a graph node.
class GraphNodePosition {
  final String noteId;
  final double x;
  final double y;
  final bool isPinned;

  const GraphNodePosition({
    required this.noteId,
    required this.x,
    required this.y,
    this.isPinned = false,
  });

  factory GraphNodePosition.fromMap(Map<String, dynamic> map) {
    double safeDouble(dynamic v, {double fallback = 0.0}) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is bool) return v ? 1.0 : 0.0;
      return double.tryParse(v.toString()) ?? fallback;
    }

    return GraphNodePosition(
      noteId: map['note_id'] as String,
      x: safeDouble(map['x']),
      y: safeDouble(map['y']),
      isPinned: map['is_pinned'] == 1 || map['is_pinned'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'x': x,
      'y': y,
      'is_pinned': isPinned ? 1 : 0,
    };
  }

  GraphNodePosition copyWith({
    String? noteId,
    double? x,
    double? y,
    bool? isPinned,
  }) {
    return GraphNodePosition(
      noteId: noteId ?? this.noteId,
      x: x ?? this.x,
      y: y ?? this.y,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  String toString() => 'GraphNodePosition(noteId: $noteId, x: $x, y: $y, isPinned: $isPinned)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GraphNodePosition && other.noteId == noteId;

  @override
  int get hashCode => noteId.hashCode;
}


