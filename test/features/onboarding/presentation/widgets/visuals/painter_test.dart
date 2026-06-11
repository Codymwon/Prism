import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/onboarding/presentation/widgets/visuals/graph_visual.dart';
import 'package:prism/features/onboarding/presentation/widgets/visuals/wikilinks_visual.dart';

void main() {
  group('GraphLinesPainter shouldRepaint tests', () {
    test('returns false when properties are identical', () {
      final painter1 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(10, 10),
        points: const [Offset(20, 20)],
      );
      final painter2 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(10, 10),
        points: const [Offset(20, 20)],
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('returns true when color changes', () {
      final painter1 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(10, 10),
        points: const [Offset(20, 20)],
      );
      final painter2 = GraphLinesPainter(
        color: Colors.blue,
        center: const Offset(10, 10),
        points: const [Offset(20, 20)],
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when center changes', () {
      final painter1 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(10, 10),
        points: const [Offset(20, 20)],
      );
      final painter2 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(15, 10),
        points: const [Offset(20, 20)],
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when points change', () {
      final painter1 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(10, 10),
        points: const [Offset(20, 20)],
      );
      final painter2 = GraphLinesPainter(
        color: Colors.red,
        center: const Offset(10, 10),
        points: const [Offset(20, 30)],
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });

  group('BeamPainter shouldRepaint tests', () {
    test('returns false when color is identical', () {
      final painter1 = BeamPainter(color: Colors.red);
      final painter2 = BeamPainter(color: Colors.red);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('returns true when color changes', () {
      final painter1 = BeamPainter(color: Colors.red);
      final painter2 = BeamPainter(color: Colors.blue);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
