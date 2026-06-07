import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../notes/data/note_model.dart';
import '../../data/graph_models.dart';
import '../../data/graph_node_repository.dart';
import '../../data/spatial_group_repository.dart';

final graphDataProvider = FutureProvider.autoDispose<({
  List<GraphNode> nodes,
  List<GraphEdge> edges,
  List<SpatialGroup> spatialGroups,
  Map<String, String> nodeToGroup,
  Map<String, List<String>> groupNodes,
})>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  ref.watch(foldersVersionProvider);
  ref.watch(spatialGroupsVersionProvider);
  
  final repo = ref.watch(graphNodeRepositoryProvider);
  final groupRepo = ref.watch(spatialGroupRepositoryProvider);
  
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

  final groups = await groupRepo.getAllSpatialGroups();
  final mappings = await groupRepo.getSpatialGroupNodeMappings();
  
  final Map<String, String> nodeToGroup = {};
  final Map<String, List<String>> groupNodes = {};

  for (final entry in mappings.entries) {
    final groupId = entry.key;
    final noteIds = entry.value;
    groupNodes[groupId] = noteIds;
    for (final noteId in noteIds) {
      nodeToGroup[noteId] = groupId;
    }
  }

  return (
    nodes: updatedNodes,
    edges: data.edges,
    spatialGroups: groups,
    nodeToGroup: nodeToGroup,
    groupNodes: groupNodes,
  );
});
