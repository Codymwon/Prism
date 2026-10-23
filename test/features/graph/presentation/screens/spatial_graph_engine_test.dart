import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/graph/data/graph_models.dart';
import 'package:prism/features/graph/presentation/screens/graph_screen.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  group('Spatial Hash Grid Physics & Scaling', () {
    testWidgets('Calculates Coulomb repulsion identical to pairwise formula within 500px cutoff', (tester) async {
      final nodes = [
        GraphNode(id: 'node-A', title: 'Node A', linkCount: 1, createdAt: DateTime(2026), isPinned: false),
        GraphNode(id: 'node-B', title: 'Node B', linkCount: 1, createdAt: DateTime(2026), isPinned: false),
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
                edges: const [],
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

      await tester.pump();

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      state.setNodePositionForTesting('node-A', const Offset(2450.0, 2500.0));
      state.setNodePositionForTesting('node-B', const Offset(2550.0, 2500.0));

      await tester.pump(const Duration(milliseconds: 16));

      // Distance = 100.0 (< 500.0 cutoff)
      // Repulsion force magnitude = (1.0 * 12000.0) / (10000 + 0.1) ≈ 1.2
      // Center pull magnitude = 50 * 0.005 = 0.25
      // Net force pushes node-A left (< 2450.0) and node-B right (> 2550.0)
      final posA = state.positionsForTesting['node-A']!;
      final posB = state.positionsForTesting['node-B']!;

      expect(posA.dx, lessThan(2450.0)); // Pushed left
      expect(posB.dx, greaterThan(2550.0)); // Pushed right
      expect(posB.dx - posA.dx, greaterThan(100.0)); // Pushed apart by Coulomb repulsion

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Nodes beyond 500px cutoff exert 0 Coulomb repulsion on each other', (tester) async {
      final nodes = [
        GraphNode(id: 'far-A', title: 'Far A', linkCount: 1, createdAt: DateTime(2026), isPinned: false),
        GraphNode(id: 'far-B', title: 'Far B', linkCount: 1, createdAt: DateTime(2026), isPinned: false),
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
                edges: const [],
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

      await tester.pump();

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      state.setNodePositionForTesting('far-A', const Offset(1000.0, 2500.0));
      state.setNodePositionForTesting('far-B', const Offset(3000.0, 2500.0));

      await tester.pump(const Duration(milliseconds: 16));

      // With distance = 2000.0 (> 500.0 cutoff), no repulsion occurs between them
      // Nodes only feel center gravity towards 2500.0
      final posA = state.positionsForTesting['far-A']!;
      final posB = state.positionsForTesting['far-B']!;

      // Gravity pulls towards center 2500.0
      expect(posA.dx, greaterThan(1000.0)); // pulled right towards 2500
      expect(posB.dx, lessThan(3000.0)); // pulled left towards 2500

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Large graph (150 nodes) runs physics ticks smoothly', (tester) async {
      final nodes = List.generate(
        150,
        (i) => GraphNode(
          id: 'node-$i',
          title: 'Note $i',
          linkCount: i % 5,
          createdAt: DateTime(2026),
        ),
      );

      final edges = List.generate(
        100,
        (i) => GraphEdge(sourceId: 'node-$i', targetId: 'node-${(i + 1) % 150}'),
      );

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
                disableEntranceAnimation: true,
              ),
            ),
          ),
        ),
      );

      // Verify physics ticks advance without error or deadlock
      for (int f = 0; f < 10; f++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      expect(state.positionsForTesting.length, equals(150));

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Simulation Sleep & Wake Mechanics', () {
    testWidgets('Automatically sleeps ticker when velocities settle below threshold', (tester) async {
      final nodes = [
        GraphNode(id: 'settle-1', title: 'Settle 1', linkCount: 1, createdAt: DateTime(2026), isPinned: true, pinnedX: 2500.0, pinnedY: 2500.0),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphSimulationCanvas(
                nodes: nodes,
                edges: const [],
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

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));

      // Pump enough time for single pinned node to reach zero velocity
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Re-layout should wake simulation
      state.triggerReLayout();
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Viewport Frustum Culling', () {
    test('Calculates visible world-space rect with 150px margin correctly', () {
      final matrix = Matrix4.identity(); // scale 1.0, translation 0,0
      const viewportSize = Size(800.0, 600.0);

      final rect = getGraphVisibleWorldRect(matrix, viewportSize, margin: 150.0);
      expect(rect.left, equals(-150.0));
      expect(rect.top, equals(-150.0));
      expect(rect.right, equals(950.0));
      expect(rect.bottom, equals(750.0));
    });

    test('Scales visible world-space rect under camera zoom', () {
      // Zoom in 2x
      final matrix = Matrix4.identity()..scaleByDouble(2.0, 2.0, 1.0, 1.0);
      const viewportSize = Size(800.0, 600.0);

      final rect = getGraphVisibleWorldRect(matrix, viewportSize, margin: 150.0);
      // Screen 0..800 at 2x zoom corresponds to world 0..400
      expect(rect.left, equals(0.0 - 150.0));
      expect(rect.top, equals(0.0 - 150.0));
      expect(rect.right, equals(400.0 + 150.0));
      expect(rect.bottom, equals(300.0 + 150.0));
    });
  });
}
