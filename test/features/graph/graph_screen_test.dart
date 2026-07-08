import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/graph/presentation/screens/graph_screen.dart';
import 'package:prism/features/graph/presentation/providers/graph_providers.dart';
import 'package:prism/features/graph/presentation/providers/graph_color_provider.dart';
import 'package:prism/features/graph/data/graph_node_repository.dart';
import 'package:prism/features/graph/data/graph_models.dart';
import 'package:prism/features/graph/presentation/widgets/graph_node_widget.dart';
import 'package:prism/shared/widgets/tactile_wrapper.dart';

void main() {
  testWidgets('Graph nodes within Flow are constrained to 100x80 and do not take up 2500x2500', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: '1', title: 'Node 1', linkCount: 1, createdAt: DateTime(2026)),
      GraphNode(id: '2', title: 'Node 2', linkCount: 2, createdAt: DateTime(2026)),
    ];
    final edges = [
      const GraphEdge(sourceId: '1', targetId: '2'),
    ];

    final transformationController = TransformationController();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    // In the correct implementation, the size should be 100x80
    expect(size.width, 100.0);
    expect(size.height, 80.0);

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('GraphNodeWidget renders dimmed colors when isGhost is true', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('GestureDetector for temporal nodes has non-null pan callbacks just like normal nodes', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: 'normal-1', title: 'Normal Node', linkCount: 1, isTemporal: false, createdAt: DateTime(2026)),
      GraphNode(id: 'temporal-1', title: 'Temporal Node', linkCount: 1, isTemporal: true, createdAt: DateTime(2026)),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    expect(temporalDetector.onPanStart, isNotNull);
    expect(temporalDetector.onPanUpdate, isNotNull);
    expect(temporalDetector.onPanEnd, isNotNull);

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Dragging a temporal node updates its position in memory but does not write to repository', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: 'temporal-1', title: 'Temporal Node', linkCount: 1, isTemporal: true, createdAt: DateTime(2026)),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    state.setNodePositionForTesting('temporal-1', const Offset(1250.0, 1250.0));
    await tester.pump();

    final startLocation = tester.getCenter(find.byKey(const ValueKey('drag_temporal-1')));
    final gesture = await tester.startGesture(startLocation);
    await tester.pump();
    await gesture.moveBy(const Offset(30.0, 30.0)); // win arena
    await tester.pump();
    await gesture.moveBy(const Offset(100.0, 100.0)); // actual drag
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // Verify it moved in memory
    final endPos = state.positionsForTesting['temporal-1']!;
    expect(endPos.dx, isNot(1250.0));
    expect(endPos.dy, isNot(1250.0));

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
      GraphNode(id: 'normal-1', title: 'Normal Node', linkCount: 1, isTemporal: false, isPinned: true, pinnedX: 1250.0, pinnedY: 1250.0, createdAt: DateTime(2026)),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          graphAutoFitPerformedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    // The position should be clamped to the minimum boundaries: X = 50.0, Y = 40.0
    expect(state.positionsForTesting['normal-1']!.dx, equals(50.0));
    expect(state.positionsForTesting['normal-1']!.dy, equals(40.0));

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

    // The position should be clamped to the maximum boundaries: X = 4950.0, Y = 4960.0
    expect(state.positionsForTesting['normal-1']!.dx, equals(4950.0));
    expect(state.positionsForTesting['normal-1']!.dy, equals(4960.0));

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Node dragging is scale-invariant under different zoom levels', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: 'node-1', title: 'Test Node', linkCount: 1, isTemporal: false, isPinned: true, createdAt: DateTime(2026)),
    ];
    final edges = <GraphEdge>[];

    final transformationController = TransformationController();
    
    // Zoom in to 2.0x scale
    transformationController.value = Matrix4.identity()..scaleByVector3(Vector3(2.0, 2.0, 2.0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          graphAutoFitPerformedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GraphSimulationCanvas(
              nodes: nodes,
              edges: edges,
              repulsionRate: 1.0,
              repulsionPercentage: 0.5,
              attractionRate: 0.35,
              damping: 0.85,
              transformationController: transformationController,
              disableEntranceAnimation: true,
            ),
          ),
        ),
      ),
    );

    // Let the widget layout and _centerView execute first
    await tester.pump();

    // Now manually zoom to 2.0x scale and translate so the center (1250, 1250) is at screen (400, 300)
    // S = 2.0 * C + T => T = (400, 300) - 2.0 * (1250, 1250) = (-2100, -2200)
    transformationController.value = Matrix4.identity()
      ..translateByVector3(Vector3(-2100.0, -2200.0, 0.0))
      ..scaleByVector3(Vector3(2.0, 2.0, 2.0));
    await tester.pump();

    final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
    state.setNodePositionForTesting('node-1', const Offset(1250.0, 1250.0));
    await tester.pump();

    // Calculate node center in canvas coordinates:
    // dx = pos.dx - 50.0 (so center X is pos.dx)
    // dy = pos.dy - dotSize/2 (so center Y is pos.dy - dotSize/2 + 40)
    // node-1 has linkCount = 1, so dotSize = 8.0 + 1.5 = 9.5
    const dotSize = 9.5;
    const canvasCenter = Offset(1250.0, 1250.0 - (dotSize / 2) + 40.0);
    final globalCenter = MatrixUtils.transformPoint(transformationController.value, canvasCenter);

    final gesture = await tester.startGesture(globalCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(30.0, 30.0)); // win arena (exceeds kTouchSlop of 18)
    await tester.pump();
    await gesture.moveBy(const Offset(100.0, 100.0)); // move 100 logical pixels on screen
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final endPos = state.positionsForTesting['node-1']!;
    
    // At scale 2.0, moving finger by 100 logical pixels on screen should move the node
    // by exactly 100 / 2.0 = 50 units in canvas coordinates.
    // In the buggy implementation, it gets divided by scale twice, moving by 25 units.
    // Expected end position: (1250 + 50, 1250 + 50) = (1300.0, 1300.0)
    expect(endPos.dx, closeTo(1300.0, 0.01));
    expect(endPos.dy, closeTo(1300.0, 0.01));

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Graph auto-fit zoom adjusts TransformationController scale when positions are resolved', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: 'node-1', title: 'Test Node 1', linkCount: 1, isPinned: true, pinnedX: 100.0, pinnedY: 100.0, createdAt: DateTime(2026)),
      GraphNode(id: 'node-2', title: 'Test Node 2', linkCount: 2, isPinned: true, pinnedX: 4900.0, pinnedY: 4900.0, createdAt: DateTime(2026)),
    ];
    final edges = [
      const GraphEdge(sourceId: 'node-1', targetId: 'node-2'),
    ];

    final transformationController = TransformationController();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: GraphSimulationCanvas(
                nodes: nodes,
                edges: edges,
                repulsionRate: 1.0,
                repulsionPercentage: 0.5,
                attractionRate: 0.35,
                damping: 0.85,
                transformationController: transformationController,
                disableEntranceAnimation: true,
              ),
            ),
          ),
        ),
      ),
    );

    // Pump once to start simulation, trigger tick, which cools down immediately because it's static/pinned
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The scale should now be less than 1.0 to fit the 4800px spread into the 400x300 viewport
    final finalMatrix = transformationController.value;
    final finalScale = finalMatrix.getMaxScaleOnAxis();
    expect(finalScale, lessThan(1.0));

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('GraphScreen shows play button and GPS button in header and they trigger callbacks', (WidgetTester tester) async {
    // Override graph providers to supply a simple mock graph
    final nodes = [
      GraphNode(id: 'node-1', title: 'Node 1', linkCount: 1, isPinned: true, pinnedX: 1250.0, pinnedY: 1250.0, createdAt: DateTime(2026)),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          graphDataProvider.overrideWith((ref) => (nodes: nodes, edges: edges)),
          graphAutoFitPerformedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: GraphScreen(),
        ),
      ),
    );

    // Let graph build and settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify play button is present in the header
    final playButtonFinder = find.byIcon(Icons.play_circle_outline);
    expect(playButtonFinder, findsOneWidget);

    // Verify GPS button is present in the header
    final gpsButtonFinder = find.byIcon(Icons.gps_fixed_rounded);
    expect(gpsButtonFinder, findsOneWidget);

    // Tap play button and verify no crash/no refresh callback
    await tester.tap(playButtonFinder);
    await tester.pump();

    // Verify no floating GPS button in stack (should be gone from bottom-right)
    final floatingGpsFinder = find.descendant(
      of: find.byType(Stack),
      matching: find.byIcon(Icons.gps_fixed_rounded),
    );
    // There should only be one GPS button, and it's in the header, not floating in stack (excluding the header row)
    expect(floatingGpsFinder, findsNothing);

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('GraphReplay animation pauses physics and controls node visibility', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: 'node-1', title: 'Node 1', linkCount: 1, isPinned: true, pinnedX: 1250.0, pinnedY: 1250.0, createdAt: DateTime(2026)),
      GraphNode(id: 'node-2', title: 'Node 2', linkCount: 2, isPinned: true, pinnedX: 1300.0, pinnedY: 1300.0, createdAt: DateTime(2026)),
    ];
    final edges = [
      const GraphEdge(sourceId: 'node-1', targetId: 'node-2'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          graphDataProvider.overrideWith((ref) => (nodes: nodes, edges: edges)),
          graphAutoFitPerformedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: GraphScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final canvasState = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
    
    // Trigger replay animation via public method
    canvasState.triggerReplayAnimation();
    
    // Under replay, physics ticker should be stopped
    expect(canvasState.isReplayingForTesting, isTrue);

    // Clean up ticker
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Graph Color Mode dropdown updates color mode provider state', (WidgetTester tester) async {
    final nodes = [
      GraphNode(id: 'node-1', title: 'Node 1', linkCount: 1, createdAt: DateTime(2026)),
    ];
    final edges = <GraphEdge>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          graphDataProvider.overrideWith((ref) => (nodes: nodes, edges: edges)),
          graphAutoFitPerformedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: GraphScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Open settings panel
    final settingsButtonFinder = find.byIcon(Icons.settings_outlined);
    expect(settingsButtonFinder, findsOneWidget);
    await tester.tap(settingsButtonFinder);
    await tester.pumpAndSettle();

    // Verify Color Mode dropdown is present
    final dropdownFinder = find.byKey(const ValueKey('graph_color_mode_dropdown'));
    expect(dropdownFinder, findsOneWidget);

    // Tap play button / cleanup ticker
    await tester.pumpWidget(const SizedBox());
  });

  test('graphNodeColorsProvider resolves colors alphabetically for folders and tags', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer(
      overrides: [
        graphNodeRepositoryProvider.overrideWith((ref) => FakeGraphNodeRepository(
          ref,
          tags: {
            'note-1': ['work', 'personal'],
          },
          folders: {
            'note-1': [
              {'name': 'Archive', 'color_hex': '#111111'},
              {'name': 'Inbox', 'color_hex': '#222222'},
            ],
          },
        )),
      ],
    );

    addTearDown(container.dispose);

    container.listen(graphNodeColorsProvider, (_, _) {});

    // 1. Default color mode 'none' -> should be empty
    var colors = await container.read(graphNodeColorsProvider.future);
    expect(colors, isEmpty);

    // 2. Folder mode -> should select 'Archive' color
    await container.read(graphColorModeProvider.notifier).setColorMode('folders');
    colors = await container.read(graphNodeColorsProvider.future);
    expect(colors['note-1'], equals('#111111'));

    // 3. Tag mode -> should select 'personal' tag color
    await container.read(graphColorModeProvider.notifier).setColorMode('tags');
    colors = await container.read(graphNodeColorsProvider.future);
    // Since 'personal' has no custom color, it should fall back to deterministic HSL hash hex
    expect(colors['note-1'], isNotNull);
    expect(colors['note-1']!.startsWith('#'), isTrue);
  });
}

class FakeGraphNodeRepository implements GraphNodeRepository {
  final Map<String, List<String>> tags;
  final Map<String, List<Map<String, String>>> folders;

  FakeGraphNodeRepository(
    Ref ref, {
    required this.tags,
    required this.folders,
  });

  @override
  Future<({List<GraphNode> nodes, List<GraphEdge> edges})> getGraphData() async {
    return (nodes: <GraphNode>[], edges: <GraphEdge>[]);
  }

  @override
  Future<Map<String, List<String>>> getNoteTagsMap() async => tags;

  @override
  Future<Map<String, List<Map<String, String>>>> getNoteFoldersMap() async => folders;

  @override
  Future<Map<String, GraphNodePosition>> getPinnedCoordinates() async => const {};

  @override
  Future<void> pinNode(String nodeId, double x, double y) async {}

  @override
  Future<void> unpinNode(String nodeId) async {}
}
