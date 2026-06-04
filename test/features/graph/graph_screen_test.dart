import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meridian/features/graph/presentation/screens/graph_screen.dart';
import 'package:meridian/features/notes/data/note_model.dart';
import 'package:meridian/features/graph/presentation/widgets/graph_node_widget.dart';
import 'package:meridian/shared/widgets/tactile_wrapper.dart';

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

  testWidgets('GraphNodeWidget renders dimmed colors when isGhost is true', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphNodeWidget(
              id: 'ghost-1',
              title: 'Ghost Note',
              linkCount: 1,
              isSelected: false,
              colorHex: '#FF0000',
              isGhost: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    // Verify the widget renders
    expect(find.text('Ghost Note'), findsOneWidget);

    // Verify the text color has the correct alpha/opacity for ghost notes
    final textWidget = tester.widget<Text>(find.byType(Text));
    final textColor = textWidget.style?.color;
    expect(textColor, isNotNull);
    expect(textColor!.a, closeTo(0.35, 0.05));

    // Verify that the AnimatedContainer (dot) uses the dimmed dot color
    final containerFinder = find.byType(AnimatedContainer);
    expect(containerFinder, findsOneWidget);
    final animatedContainer = tester.widget<AnimatedContainer>(containerFinder);
    final decoration = animatedContainer.decoration as BoxDecoration;
    final color = decoration.color;
    expect(color, isNotNull);
    expect(color!.a, closeTo(0.35, 0.05));

    // Verify it is still interactive/tappable
    await tester.tap(find.byType(TactileWrapper));
    expect(tapped, isTrue);
  });
}
