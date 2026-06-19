import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_model.freezed.dart';

@freezed
class VirtualFolder with _$VirtualFolder {
  const VirtualFolder._();

  const factory VirtualFolder({
    required String id,
    required String name,
    @Default('#7C6FF7') String colorHex,
    @Default('folder') String icon,
    required DateTime createdAt,
    required int sortOrder,
    @Default(0) int noteCount,
  }) = _VirtualFolder;

  factory VirtualFolder.fromMap(Map<String, dynamic> map) {
    // getAllFolders() uses rawQuery with LEFT JOIN — sqflite on Android can
    // return INTEGER columns as double or bool (0 → false) from JOIN queries.
    int safeInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return VirtualFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? '#7C6FF7',
      icon: map['icon'] as String? ?? 'folder',
      createdAt: DateTime.fromMillisecondsSinceEpoch(safeInt(map['created_at'])),
      sortOrder: safeInt(map['sort_order']),
      noteCount: safeInt(map['note_count']),
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

  @override
  String toString() => 'VirtualFolder(id: $id, name: $name, noteCount: $noteCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VirtualFolder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

