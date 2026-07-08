import 'package:freezed_annotation/freezed_annotation.dart';

part 'graph_models.freezed.dart';

/// Model representing coordinates and pin state of a graph node.
@freezed
class GraphNodePosition with _$GraphNodePosition {
  const GraphNodePosition._();

  const factory GraphNodePosition({
    required String noteId,
    required double x,
    required double y,
    @Default(false) bool isPinned,
  }) = _GraphNodePosition;

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

  @override
  String toString() => 'GraphNodePosition(noteId: $noteId, x: $x, y: $y, isPinned: $isPinned)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GraphNodePosition && other.noteId == noteId;

  @override
  int get hashCode => noteId.hashCode;
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
  final DateTime createdAt;

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
    required this.createdAt,
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A graph edge between two notes (for Graph View).
class GraphEdge {
  final String sourceId;
  final String targetId;

  const GraphEdge({required this.sourceId, required this.targetId});
}


