class VirtualFolder {
  final String id;
  final String name;
  final String colorHex;
  final String icon;
  final DateTime createdAt;
  final int sortOrder;
  final int noteCount;

  VirtualFolder({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.icon,
    required this.createdAt,
    required this.sortOrder,
    this.noteCount = 0,
  });

  factory VirtualFolder.fromMap(Map<String, dynamic> map) {
    return VirtualFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? '#7C6FF7',
      icon: map['icon'] as String? ?? 'folder',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      sortOrder: map['sort_order'] as int? ?? 0,
      noteCount: map['note_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sort_order': sortOrder,
    };
  }

  VirtualFolder copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? icon,
    DateTime? createdAt,
    int? sortOrder,
    int? noteCount,
  }) {
    return VirtualFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      noteCount: noteCount ?? this.noteCount,
    );
  }

  @override
  String toString() => 'VirtualFolder(id: $id, name: $name, noteCount: $noteCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VirtualFolder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
