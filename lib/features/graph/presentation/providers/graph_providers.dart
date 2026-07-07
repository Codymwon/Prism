import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/graph_models.dart';
import '../../data/graph_node_repository.dart';

final graphViewportStateProvider = StateProvider<Matrix4?>((ref) => null);
final graphAutoFitPerformedProvider = StateProvider<bool>((ref) => false);


final graphDataProvider = FutureProvider.autoDispose<({
  List<GraphNode> nodes,
  List<GraphEdge> edges,
})>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  ref.watch(foldersVersionProvider);
  
  final repo = ref.watch(graphNodeRepositoryProvider);
  
  final data = await repo.getGraphData();
  final Map<String, GraphNodePosition> pinnedCoords = await repo.getPinnedCoordinates();

  final updatedNodes = data.nodes.map((node) {
    final pinned = pinnedCoords[node.id];
    if (pinned != null) {
      return node.copyWith(
        isPinned: true,
        pinnedX: pinned.x,
        pinnedY: pinned.y,
      );
    }
    return node;
  }).toList();

  return (
    nodes: updatedNodes,
    edges: data.edges,
  );
});
