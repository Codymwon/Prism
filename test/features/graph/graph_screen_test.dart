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

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
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

  testWidgets('GestureDetector for temporal nodes has null pan callbacks, while normal nodes have non-null callbacks', (WidgetTester tester) async {
    final nodes = [
      const GraphNode(id: 'normal-1', title: 'Normal Node', linkCount: 1, isTemporal: false),
      const GraphNode(id: 'temporal-1', title: 'Temporal Node', linkCount: 1, isTemporal: true),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphSimulationCanvas(
              nodes: nodes,
              edges: edges,
              repulsionRate: 1.0,
              repulsionPercentage: 0.5,
              attractionRate: 0.35,
              damping: 0.85,
              transformationController: TransformationController(),
              disableEntranceAnimation: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final normalDetector = tester.widget<GestureDetector>(find.byKey(const ValueKey('drag_normal-1')));
    final temporalDetector = tester.widget<GestureDetector>(find.byKey(const ValueKey('drag_temporal-1')));

    expect(normalDetector.onPanStart, isNotNull);
    expect(normalDetector.onPanUpdate, isNotNull);
    expect(normalDetector.onPanEnd, isNotNull);

    expect(temporalDetector.onPanStart, isNull);
    expect(temporalDetector.onPanUpdate, isNull);
    expect(temporalDetector.onPanEnd, isNull);

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Coordinate clamping keeps dragged node within bounds', (WidgetTester tester) async {
    // Set viewport size big enough to contain the canvas/node
    tester.view.physicalSize = const Size(2500.0, 2500.0);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(2500.0, 2500.0));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });

    final nodes = [
      const GraphNode(id: 'normal-1', title: 'Normal Node', linkCount: 1, isTemporal: false, isPinned: true),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphSimulationCanvas(
              nodes: nodes,
              edges: edges,
              repulsionRate: 1.0,
              repulsionPercentage: 0.5,
              attractionRate: 0.35,
              damping: 0.85,
              transformationController: TransformationController(),
              disableEntranceAnimation: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
    
    // Set node position to center initially
    state.setNodePositionForTesting('normal-1', const Offset(1250.0, 1250.0));
    await tester.pump();

    // Drag far to the top-left (off-canvas) using startGesture
    final startLocation1 = tester.getCenter(find.byKey(const ValueKey('drag_normal-1')));
    final gesture1 = await tester.startGesture(startLocation1);
    await tester.pump();
    await gesture1.moveBy(const Offset(-50.0, -50.0)); // win arena
    await tester.pump();
    await gesture1.moveBy(const Offset(-3000.0, -3000.0)); // actual drag
    await tester.pump();
    await gesture1.up();
    await tester.pump();

    // The position should be clamped to the minimum boundaries: X = 40.0, Y = 30.0
    expect(state.positionsForTesting['normal-1']!.dx, equals(40.0));
    expect(state.positionsForTesting['normal-1']!.dy, equals(30.0));

    // Drag far to the bottom-right (off-canvas)
    final startLocation2 = tester.getCenter(find.byKey(const ValueKey('drag_normal-1')));
    final gesture2 = await tester.startGesture(startLocation2);
    await tester.pump();
    await gesture2.moveBy(const Offset(50.0, 50.0)); // win arena
    await tester.pump();
    await gesture2.moveBy(const Offset(5000.0, 5000.0)); // actual drag
    await tester.pump();
    await gesture2.up();
    await tester.pump();

    // The position should be clamped to the maximum boundaries: X = 2460.0, Y = 2470.0
    expect(state.positionsForTesting['normal-1']!.dx, equals(2460.0));
    expect(state.positionsForTesting['normal-1']!.dy, equals(2470.0));

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });
}
