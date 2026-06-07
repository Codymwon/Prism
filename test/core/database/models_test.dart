import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/graph/data/graph_models.dart';
import 'package:prism/features/notes/data/audio_bookmark_model.dart';

void main() {
  group('GraphNodePosition model type safety', () {
    test('fromMap parses double and bool and int correctly', () {
      final map = {
        'note_id': 'note-1',
        'x': 10, // int
        'y': false, // bool (0) -> fallback/converted
        'is_pinned': 1, // int representing true
      };
      final pos = GraphNodePosition.fromMap(map);
      expect(pos.noteId, equals('note-1'));
      expect(pos.x, equals(10.0));
      expect(pos.y, equals(0.0));
      expect(pos.isPinned, isTrue);
    });

    test('toMap and copyWith work correctly', () {
      const pos = GraphNodePosition(noteId: 'note-1', x: 2.0, y: 3.0, isPinned: true);
      final map = pos.toMap();
      expect(map['note_id'], equals('note-1'));
      expect(map['x'], equals(2.0));
      expect(map['y'], equals(3.0));
      expect(map['is_pinned'], equals(1));

      final copied = pos.copyWith(x: 4.5, isPinned: false);
      expect(copied.noteId, equals('note-1'));
      expect(copied.x, equals(4.5));
      expect(copied.y, equals(3.0));
      expect(copied.isPinned, isFalse);
    });
  });

  group('SpatialGroup model type safety', () {
    test('fromMap parses date and string correctly', () {
      final map = {
        'id': 'g-1',
        'name': 'Group A',
        'color_hex': '#123456',
        'created_at': 1700000000000.0, // double timestamp
      };
      final group = SpatialGroup.fromMap(map);
      expect(group.id, equals('g-1'));
      expect(group.name, equals('Group A'));
      expect(group.colorHex, equals('#123456'));
      expect(group.createdAt.millisecondsSinceEpoch, equals(1700000000000));
    });

    test('toMap and copyWith work correctly', () {
      final date = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final group = SpatialGroup(id: 'g-1', name: 'Group A', colorHex: '#123456', createdAt: date);
      final map = group.toMap();
      expect(map['id'], equals('g-1'));
      expect(map['name'], equals('Group A'));
      expect(map['color_hex'], equals('#123456'));
      expect(map['created_at'], equals(1700000000000));

      final copied = group.copyWith(name: 'Group B');
      expect(copied.name, equals('Group B'));
      expect(copied.colorHex, equals('#123456'));
    });
  });

  group('SpatialGroupNode model', () {
    test('fromMap and toMap and copyWith work correctly', () {
      final map = {
        'group_id': 'g-1',
        'note_id': 'n-1',
      };
      final mapping = SpatialGroupNode.fromMap(map);
      expect(mapping.groupId, equals('g-1'));
      expect(mapping.noteId, equals('n-1'));

      final outMap = mapping.toMap();
      expect(outMap['group_id'], equals('g-1'));
      expect(outMap['note_id'], equals('n-1'));

      final copied = mapping.copyWith(noteId: 'n-2');
      expect(copied.groupId, equals('g-1'));
      expect(copied.noteId, equals('n-2'));
    });
  });

  group('AudioBookmark model type safety', () {
    test('fromMap parses ints, doubles and dates correctly', () {
      final map = {
        'id': 'b-1',
        'note_id': 'n-1',
        'attachment_path': 'path/to/audio.m4a',
        'timestamp_ms': 5000.0, // double representing milliseconds
        'annotation_text': 'Audio mark',
        'created_at': 1700000000000,
      };
      final bookmark = AudioBookmark.fromMap(map);
      expect(bookmark.id, equals('b-1'));
      expect(bookmark.noteId, equals('n-1'));
      expect(bookmark.attachmentPath, equals('path/to/audio.m4a'));
      expect(bookmark.timestampMs, equals(5000));
      expect(bookmark.annotationText, equals('Audio mark'));
      expect(bookmark.createdAt.millisecondsSinceEpoch, equals(1700000000000));
    });

    test('toMap and copyWith work correctly', () {
      final date = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final bookmark = AudioBookmark(
        id: 'b-1',
        noteId: 'n-1',
        attachmentPath: 'path/to/audio.m4a',
        timestampMs: 5000,
        annotationText: 'Audio mark',
        createdAt: date,
      );
      final map = bookmark.toMap();
      expect(map['id'], equals('b-1'));
      expect(map['note_id'], equals('n-1'));
      expect(map['attachment_path'], equals('path/to/audio.m4a'));
      expect(map['timestamp_ms'], equals(5000));
      expect(map['annotation_text'], equals('Audio mark'));
      expect(map['created_at'], equals(1700000000000));

      final copied = bookmark.copyWith(timestampMs: 6000);
      expect(copied.timestampMs, equals(6000));
    });
  });
}
