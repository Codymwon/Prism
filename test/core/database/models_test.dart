import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/graph/data/graph_models.dart';
import 'package:prism/features/editor/data/audio_bookmark_model.dart';

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
