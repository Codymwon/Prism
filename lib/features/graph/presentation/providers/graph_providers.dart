import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/database/database_service.dart';
import '../../data/graph_models.dart';
import '../../data/graph_node_repository.dart';

part 'graph_providers.g.dart';

@Riverpod(keepAlive: true)
class GraphViewportState extends _$GraphViewportState {
  final Matrix4? _initialValue;
  GraphViewportState([this._initialValue]);

  @override
  Matrix4? build() => _initialValue;

  @override
  Matrix4? get state => super.state;

  @override
  set state(Matrix4? value) => super.state = value;
}

@Riverpod(keepAlive: true)
class GraphAutoFitPerformed extends _$GraphAutoFitPerformed {
  final bool? _initialValue;
  GraphAutoFitPerformed([this._initialValue]);

  @override
  bool build() => _initialValue ?? false;

  @override
  bool get state => super.state;

  @override
  set state(bool value) => super.state = value;
}


final graphDataProvider = FutureProvider.autoDispose<({
  List<GraphNode> nodes,
  List<GraphEdge> edges,
})>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(tableVersionProvider(DbTable.noteLinks));
  ref.watch(tableVersionProvider(DbTable.graphPositions));
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
