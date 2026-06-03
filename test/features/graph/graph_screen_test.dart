import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/features/graph/presentation/screens/graph_screen.dart';
import 'package:meridian/features/notes/data/note_model.dart';

void main() {
  testWidgets('Graph nodes within Flow are constrained to 80x60 and do not take up 2500x2500', (WidgetTester tester) async {
    final nodes = [
      const GraphNode(id: '1', title: 'Node 1', linkCount: 1),
      const GraphNode(id: '2', title: 'Node 2', linkCount: 2),
    ];
    final edges = [
      const GraphEdge(sourceId: '1', targetId: '2'),
    ];

    final transformationController = TransformationController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphSimulationCanvas(
            nodes: nodes,
            edges: edges,
            repulsionRate: 1.0,
            repulsionPercentage: 0.5,
            attractionRate: 0.35,
            damping: 0.85,
            transformationController: transformationController,
          ),
        ),
      ),
    );

    // Let the physics simulation frame ticker start and layout
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find GestureDetectors which wrap the node content inside the Flow widget
    final flowFinder = find.byType(Flow);
    final nodeDetectorFinder = find.descendant(
      of: flowFinder,
      matching: find.byType(GestureDetector),
    );
    expect(nodeDetectorFinder, findsNWidgets(4));

    // Inspect the size of the first GestureDetector child of Flow
    final size = tester.getSize(nodeDetectorFinder.first);
    
    // In the buggy implementation, the size will be 2500x2500 (matching the canvas / parent constraints)
    // In the correct implementation, the size should be 80x60
    expect(size.width, 80.0);
    expect(size.height, 60.0);
  });
}
