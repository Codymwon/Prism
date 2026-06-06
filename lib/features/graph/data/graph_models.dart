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

/// Model representing a spatial group configurations.
class SpatialGroup {
  final String id;
  final String name;
  final String colorHex;
  final DateTime createdAt;

  const SpatialGroup({
    required this.id,
    required this.name,
    this.colorHex = '#7C6FF7',
    required this.createdAt,
  });

  factory SpatialGroup.fromMap(Map<String, dynamic> map) {
    int safeInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return SpatialGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? '#7C6FF7',
      createdAt: DateTime.fromMillisecondsSinceEpoch(safeInt(map['created_at'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  SpatialGroup copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return SpatialGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SpatialGroup(id: $id, name: $name, colorHex: $colorHex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpatialGroup && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Model mapping nodes to spatial groups.
class SpatialGroupNode {
  final String groupId;
  final String noteId;

  const SpatialGroupNode({
    required this.groupId,
    required this.noteId,
  });

  factory SpatialGroupNode.fromMap(Map<String, dynamic> map) {
    return SpatialGroupNode(
      groupId: map['group_id'] as String,
      noteId: map['note_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'note_id': noteId,
    };
  }

  SpatialGroupNode copyWith({
    String? groupId,
    String? noteId,
  }) {
    return SpatialGroupNode(
      groupId: groupId ?? this.groupId,
      noteId: noteId ?? this.noteId,
    );
  }

  @override
  String toString() => 'SpatialGroupNode(groupId: $groupId, noteId: $noteId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialGroupNode && other.groupId == groupId && other.noteId == noteId;

  @override
  int get hashCode => Object.hash(groupId, noteId);
}
