import 'dart:math';
import 'dart:typed_data';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../data/graph_node_repository.dart';
import '../providers/graph_providers.dart';
import '../providers/graph_color_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../data/graph_models.dart';
import '../widgets/graph_settings_panel.dart';
import '../widgets/graph_header.dart';
import '../widgets/graph_empty_state.dart';
import '../widgets/graph_node_widget.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/services/analytics_service.dart';
import 'package:prism/l10n/l10n.dart';


class GraphScreen extends ConsumerWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GraphScreenContent();
  }
}

class GraphScreenContent extends ConsumerStatefulWidget {
  const GraphScreenContent({super.key});

  @override
  ConsumerState<GraphScreenContent> createState() => _GraphScreenContentState();
}

class _GraphScreenContentState extends ConsumerState<GraphScreenContent> {
  late TransformationController _transformationController;
  final GlobalKey<GraphSimulationCanvasState> _canvasKey = GlobalKey<GraphSimulationCanvasState>();

  // Settings panel toggle
  bool _showSettings = false;

  // Simulation physics parameters (Obsidian-Style)
  // repulsionPercentage=0.9  →  restLength = 120 / (0.9+0.1) = 120 px  (mobile-friendly)
  double _repulsionRate = 0.6;            // Repelling charge strength
  double _repulsionPercentage = 0.9;      // Controls Rest Length: restLength = 120 * (1 / (repulsionPercentage + 0.1))
  double _attractionRate = 0.45;          // Elastic spring stiffness
  double _damping = 0.88;                 // Simulation Friction / drag resistance

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('view_graph');
    _transformationController = TransformationController();
    
    final savedViewport = ref.read(graphViewportStateProvider);
    if (savedViewport != null) {
      _transformationController.value = savedViewport;
      // If we already have a saved viewport, we don't need to auto-fit again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(graphAutoFitPerformedProvider.notifier).state = true;
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerView();
      });
    }

    _transformationController.addListener(_onViewportChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onViewportChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onViewportChanged() {
    if (!mounted) return;
    ref.read(graphViewportStateProvider.notifier).state = _transformationController.value;
  }

  void _centerView() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    const canvasWidth = 5000.0;
    const canvasHeight = 5000.0;
    final x = -(canvasWidth - size.width) / 2;
    final y = -(canvasHeight - size.height) / 2;
    _transformationController.value = Matrix4.translationValues(x, y, 0.0);
  }

  void _triggerReLayout() {
    _canvasKey.currentState?.triggerReLayout();
  }

  void _triggerReplayAnimation() {
    _canvasKey.currentState?.triggerReplayAnimation();
  }

  void _resetToDefaults() {
    setState(() {
      _repulsionRate = 0.6;
      _repulsionPercentage = 0.9;
      _attractionRate = 0.45;
      _damping = 0.88;
      _triggerReLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(graphDataProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: Column(
        children: [
          SafeArea(
            child: GraphHeader(
              showSettings: _showSettings,
              onReplay: _triggerReplayAnimation,
              onFocusCenter: () => _canvasKey.currentState?.fitToContent(),
              onSettingsToggle: () => setState(() => _showSettings = !_showSettings),
            ),
          ),
            Expanded(
              child: () {
                if (graphAsync.hasValue) {
                  final data = graphAsync.requireValue;
                  if (data.nodes.isEmpty) {
                    return const GraphEmptyState();
                  }
                  return Stack(
                    children: [
                      // Continuous Spring-Physics Graph simulation viewport (isolated rebuilds!)
                      Positioned.fill(
                        child: GraphSimulationCanvas(
                          key: _canvasKey,
                          nodes: data.nodes,
                          edges: data.edges,
                          repulsionRate: _repulsionRate,
                          repulsionPercentage: _repulsionPercentage,
                          attractionRate: _attractionRate,
                          damping: _damping,
                          transformationController: _transformationController,
                        ),
                      ),
                      
                      // Floating dynamic settings panel (Obsidian style)
                      if (_showSettings)
                        GraphSettingsPanel(
                          repulsionRate: _repulsionRate,
                          repulsionPercentage: _repulsionPercentage,
                          attractionRate: _attractionRate,
                          damping: _damping,
                          onChangedRepulsionRate: (val) => setState(() => _repulsionRate = val),
                          onChangedRepulsionPercentage: (val) => setState(() => _repulsionPercentage = val),
                          onChangedAttractionRate: (val) => setState(() => _attractionRate = val),
                          onChangedDamping: (val) => setState(() => _damping = val),
                          onClose: () => setState(() => _showSettings = false),
                          onResetDefaults: _resetToDefaults,
                          onReLayout: _triggerReLayout,
                        ),
                    ],
                  );
                } else if (graphAsync.hasError) {
                  return Center(child: Text(context.l10n.graph_screen_error(graphAsync.error.toString())));
                } else {
                  return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'));
                }
              }(),
            ),
          ],
        ),
      );
  }
}

// ─── Continuous Spring-Physics Graph simulation viewport (isolated rebuilds!) ───
class GraphSimulationCanvas extends ConsumerStatefulWidget {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final double repulsionRate;
  final double repulsionPercentage;
  final double attractionRate;
  final double damping;
  final TransformationController transformationController;
  final bool disableEntranceAnimation;

  const GraphSimulationCanvas({
    super.key,
    required this.nodes,
    required this.edges,
    required this.repulsionRate,
    required this.repulsionPercentage,
    required this.attractionRate,
    required this.damping,
    required this.transformationController,
    this.disableEntranceAnimation = false,
  });

  @override
  ConsumerState<GraphSimulationCanvas> createState() => GraphSimulationCanvasState();
}

class GraphSimulationCanvasState extends ConsumerState<GraphSimulationCanvas> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final _RepaintNotifier _repaintNotifier = _RepaintNotifier();
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _velocities = {};
  String? _draggedNodeId;
  String? _selectedNodeId;
  bool _playedEntranceAnimation = false;
  final _rand = Random();

  final Map<String, int> _nodeIndices = {};
  Float64List? _flatPositions;
  Float64List? _flatVelocities;
  Float64List? _flatForces;

  // Cache to store pre-built static subtrees of node widgets
  final Map<String, Widget> _nodeContentCache = {};


  bool _isReplaying = false;
  final Map<String, double> _nodeOpacities = {};
  DateTime? _replayStartTime;
  List<String> _bfsOrder = [];
  
  AnimationController? _viewportAnimationController;
  Animation<Matrix4>? _viewportAnimation;

  @visibleForTesting
  bool get isReplayingForTesting => _isReplaying;

  void triggerReplayAnimation() {
    if (widget.nodes.isEmpty) return;
    
    // Reset positions to a compact center cluster for replay organic growth
    const centerX = 2500.0;
    const centerY = 2500.0;
    for (final node in widget.nodes) {
      _positions[node.id] = Offset(centerX, centerY);
      _velocities[node.id] = Offset.zero;
    }
    
    setState(() {
      _isReplaying = true;
      _nodeOpacities.clear();
      for (final n in widget.nodes) {
        _nodeOpacities[n.id] = 0.0;
      }
      _bfsOrder = _calculateBfsOrder();
      _replayStartTime = DateTime.now();
    });
    _wakeSimulation();
  }

  void _spawnNearParent(String nodeId) {
    // Find any already-revealed neighbor
    final revealedNeighborId = widget.edges
        .where((edge) => edge.sourceId == nodeId || edge.targetId == nodeId)
        .map((edge) => edge.sourceId == nodeId ? edge.targetId : edge.sourceId)
        .firstWhereOrNull((neighborId) => (_nodeOpacities[neighborId] ?? 0.0) > 0.0);

    if (revealedNeighborId != null) {
      final parentPos = _positions[revealedNeighborId];
      if (parentPos != null) {
        final angle = _rand.nextDouble() * 2 * pi;
        _positions[nodeId] = Offset(
          parentPos.dx + cos(angle) * 10.0,
          parentPos.dy + sin(angle) * 10.0,
        );
        return;
      }
    }

    // Default to center if no parent/neighbor is revealed yet
    final angle = _rand.nextDouble() * 2 * pi;
    _positions[nodeId] = Offset(
      2500.0 + cos(angle) * 10.0,
      2500.0 + sin(angle) * 10.0,
    );
  }

  List<String> _calculateBfsOrder() {
    if (widget.nodes.isEmpty) return [];
    
    // Find the node with the highest linkCount
    final startNode = widget.nodes.reduce((a, b) => a.linkCount >= b.linkCount ? a : b);
    
    final order = <String>[];
    final visited = <String>{};
    final queue = Queue<String>();
    
    // Build adjacency list for edges
    final adj = <String, List<String>>{};
    for (final node in widget.nodes) {
      adj[node.id] = [];
    }
    for (final edge in widget.edges) {
      if (adj.containsKey(edge.sourceId) && adj.containsKey(edge.targetId)) {
        adj[edge.sourceId]!.add(edge.targetId);
        adj[edge.targetId]!.add(edge.sourceId);
      }
    }
    
    queue.add(startNode.id);
    visited.add(startNode.id);
    
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      order.add(current);
      
      final neighbors = adj[current]!..sort();
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    
    // Add any disconnected nodes
    for (final node in widget.nodes) {
      if (!visited.contains(node.id)) {
        order.add(node.id);
      }
    }
    
    return order;
  }

  @visibleForTesting
  Map<String, Offset> get positionsForTesting => _positions;

  @visibleForTesting
  void setNodePositionForTesting(String id, Offset offset) {
    _positions[id] = offset;
    _repaintNotifier.notify();
  }


  @override
  void initState() {
    super.initState();
    _initializePositions(widget.nodes);
    _ticker = createTicker(_tick);
    _ticker.start();

    _viewportAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _viewportAnimationController!.addListener(() {
      if (_viewportAnimation != null) {
        widget.transformationController.value = _viewportAnimation!.value;
      }
    });
    
    // Play entrance animation once, then mark played
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _playedEntranceAnimation = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant GraphSimulationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsWake = false;

    // If nodes changed, initialize positions for any new ones
    if (!const ListEquality().equals(oldWidget.nodes, widget.nodes)) {
      _initializePositions(widget.nodes);
      _nodeContentCache.clear();
      needsWake = true;
    }

    if (oldWidget.edges != widget.edges ||
        oldWidget.repulsionRate != widget.repulsionRate ||
        oldWidget.repulsionPercentage != widget.repulsionPercentage ||
        oldWidget.attractionRate != widget.attractionRate ||
        oldWidget.damping != widget.damping) {
      needsWake = true;
    }

    if (needsWake) {
      _wakeSimulation();
    }
  }

  // Pre-builds static widget subtrees once
  void _buildNodeContentCache(Map<String, String?> resolvedColors) {
    _nodeContentCache.clear();
    for (final gn in widget.nodes) {
      final isSelected = _selectedNodeId == gn.id;
      final resolvedColor = resolvedColors[gn.id] ?? gn.colorHex;
      _nodeContentCache[gn.id] = GraphNodeWidget(
        id: gn.id,
        title: gn.title,
        linkCount: gn.linkCount,
        isSelected: isSelected,
        colorHex: resolvedColor,
        isTemporal: gn.isTemporal,
        temporalType: gn.temporalType,
        isGhost: gn.isGhost,
        isPinned: gn.isPinned,
        onUnpin: () => ref.read(graphNodeRepositoryProvider).unpinNode(gn.id),
        onTap: () {
          if (gn.isTemporal) return;
          setState(() {
            _selectedNodeId = gn.id;
            _nodeContentCache.clear(); // Rebuild with selection highlights!
          });
          context.push('/editor/${gn.id}');
        },
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaintNotifier.dispose();
    _viewportAnimationController?.dispose();
    super.dispose();
  }

  void _wakeSimulation() {
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void triggerReLayout() {
    const centerX = 2500.0;
    const centerY = 2500.0;
    
    for (final node in widget.nodes) {
      final angle = _rand.nextDouble() * 2 * pi;
      final radius = 50 + _rand.nextDouble() * 150;
      _positions[node.id] = Offset(
        centerX + cos(angle) * radius,
        centerY + sin(angle) * radius,
      );
      _velocities[node.id] = Offset.zero;
    }
    _repaintNotifier.notify();
    _wakeSimulation();
  }

  void _initializePositions(List<GraphNode> nodes) {
    const centerX = 2500.0;
    const centerY = 2500.0;

    // Clean up orphaned node coordinates
    final validIds = nodes.map((n) => n.id).toSet();
    _positions.removeWhere((key, _) => !validIds.contains(key));
    _velocities.removeWhere((key, _) => !validIds.contains(key));

    _nodeIndices.clear();
    for (int i = 0; i < nodes.length; i++) {
      _nodeIndices[nodes[i].id] = i;
    }

    final n = nodes.length;
    _flatPositions = Float64List(2 * n);
    _flatVelocities = Float64List(2 * n);
    _flatForces = Float64List(2 * n);

    for (final gn in nodes) {
      if (gn.isPinned &&
          gn.pinnedX != null &&
          gn.pinnedY != null &&
          gn.pinnedX!.isFinite &&
          gn.pinnedY!.isFinite) {
        _positions[gn.id] = Offset(gn.pinnedX!, gn.pinnedY!);
        _velocities[gn.id] = Offset.zero;
      } else if (!_positions.containsKey(gn.id)) {
        // Soft cosmic distribution outward from the center
        final angle = _rand.nextDouble() * 2 * pi;
        final radius = 50 + _rand.nextDouble() * 150;
        _positions[gn.id] = Offset(
          centerX + cos(angle) * radius,
          centerY + sin(angle) * radius,
        );
        _velocities[gn.id] = Offset.zero;
      }
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted || _positions.isEmpty || widget.nodes.isEmpty) return;

    if (_isReplaying) {
      final now = DateTime.now();
      final startTime = _replayStartTime ?? now;
      final elapsedMs = now.difference(startTime).inMilliseconds;
      
      bool allFinished = true;
      
      for (int i = 0; i < _bfsOrder.length; i++) {
        final nodeId = _bfsOrder[i];
        final staggerDelay = i * 80;
        final startRevealTime = staggerDelay;
        
        if (elapsedMs < startRevealTime) {
          _nodeOpacities[nodeId] = 0.0;
          allFinished = false;
        } else {
          final fadeProgress = (elapsedMs - startRevealTime) / 300.0;
          final opacity = fadeProgress.clamp(0.0, 1.0);
          
          if ((_nodeOpacities[nodeId] ?? 0.0) == 0.0 && opacity > 0.0) {
            _spawnNearParent(nodeId);
          }
          
          _nodeOpacities[nodeId] = opacity;
          if (opacity < 1.0) {
            allFinished = false;
          }
        }
      }
      
      _repaintNotifier.notify();
      
      if (allFinished) {
        setState(() {
          _isReplaying = false;
          _nodeOpacities.clear();
        });
        fitToContent();
        ref.read(graphAutoFitPerformedProvider.notifier).state = true;
      }
    }

    const centerX = 2500.0;
    const centerY = 2500.0;

    final n = widget.nodes.length;
    // Ensure lists are allocated and correct size
    if (_flatPositions == null || _flatPositions!.length != 2 * n) {
      _flatPositions = Float64List(2 * n);
      _flatVelocities = Float64List(2 * n);
      _flatForces = Float64List(2 * n);
      _nodeIndices.clear();
      for (int i = 0; i < n; i++) {
        _nodeIndices[widget.nodes[i].id] = i;
      }
    }

    // Copy positions and velocities from Map to flat array
    for (int i = 0; i < n; i++) {
      final id = widget.nodes[i].id;
      final pos = _positions[id] ?? const Offset(centerX, centerY);
      _flatPositions![2 * i] = pos.dx;
      _flatPositions![2 * i + 1] = pos.dy;

      final vel = _velocities[id] ?? Offset.zero;
      _flatVelocities![2 * i] = vel.dx;
      _flatVelocities![2 * i + 1] = vel.dy;
    }

    // 1. Initialize forces to zero
    _flatForces!.fillRange(0, 2 * n, 0.0);

    // 2. Coulomb Repulsion: push all nodes apart (n^2 complexity but fast for small sets)
    final double repulsionRateVal = widget.repulsionRate;
    for (int i = 0; i < n; i++) {
      final idA = widget.nodes[i].id;
      final double opacityA = _isReplaying ? (_nodeOpacities[idA] ?? 0.0) : 1.0;
      if (opacityA <= 0.0) continue; // Inactive node feels/exerts no repulsion

      final double pxA = _flatPositions![2 * i];
      final double pyA = _flatPositions![2 * i + 1];
      for (int j = i + 1; j < n; j++) {
        final idB = widget.nodes[j].id;
        final double opacityB = _isReplaying ? (_nodeOpacities[idB] ?? 0.0) : 1.0;
        if (opacityB <= 0.0) continue;

        final double pxB = _flatPositions![2 * j];
        final double pyB = _flatPositions![2 * j + 1];

        double dx = pxA - pxB;
        double dy = pyA - pyB;
        double distSq = dx * dx + dy * dy;
        if (distSq == 0.0) {
          final angle = _rand.nextDouble() * 2 * pi;
          dx = cos(angle) * 0.1;
          dy = sin(angle) * 0.1;
          distSq = 0.01;
        }
        final double distance = sqrt(distSq);

        if (distance < 500.0) { // Repelling cutoff range
          // Coulomb Force = (ChargeStrength) / dist^2
          final double forceMagnitude = (repulsionRateVal * 12000.0) / (distSq + 0.1);
          final double fX = (dx / distance) * forceMagnitude;
          final double fY = (dy / distance) * forceMagnitude;

          _flatForces![2 * i] += fX;
          _flatForces![2 * i + 1] += fY;
          _flatForces![2 * j] -= fX;
          _flatForces![2 * j + 1] -= fY;
        }
      }
    }

    // 3. Hooke Spring Attraction: pull connected nodes together
    final double attractionRateVal = widget.attractionRate;
    final double restLength = 120.0 * (1.0 / (widget.repulsionPercentage + 0.1));
    for (final edge in widget.edges) {
      final idxA = _nodeIndices[edge.sourceId];
      final idxB = _nodeIndices[edge.targetId];

      if (idxA != null && idxB != null) {
        final idA = edge.sourceId;
        final idB = edge.targetId;
        final double opacityA = _isReplaying ? (_nodeOpacities[idA] ?? 0.0) : 1.0;
        final double opacityB = _isReplaying ? (_nodeOpacities[idB] ?? 0.0) : 1.0;

        if (opacityA <= 0.0 || opacityB <= 0.0) continue; // Both nodes must be active

        final double pxA = _flatPositions![2 * idxA];
        final double pyA = _flatPositions![2 * idxA + 1];
        final double pxB = _flatPositions![2 * idxB];
        final double pyB = _flatPositions![2 * idxB + 1];

        final double dx = pxB - pxA;
        final double dy = pyB - pyA;
        final double distance = sqrt(dx * dx + dy * dy) + 0.1;

        final double displacement = distance - restLength;

        // Elastic Force = stiffness * displacement
        final double forceMagnitude = attractionRateVal * 0.12 * displacement;
        final double fX = (dx / distance) * forceMagnitude;
        final double fY = (dy / distance) * forceMagnitude;

        _flatForces![2 * idxA] += fX;
        _flatForces![2 * idxA + 1] += fY;
        _flatForces![2 * idxB] -= fX;
        _flatForces![2 * idxB + 1] -= fY;
      }
    }

    // 4. Center Gravity Force: keep nodes centered in viewport
    const double gravityStrength = 0.008;
    for (int i = 0; i < n; i++) {
      final id = widget.nodes[i].id;
      final double opacity = _isReplaying ? (_nodeOpacities[id] ?? 0.0) : 1.0;
      if (opacity <= 0.0) continue;

      final double px = _flatPositions![2 * i];
      final double py = _flatPositions![2 * i + 1];
      _flatForces![2 * i] += (centerX - px) * gravityStrength;
      _flatForces![2 * i + 1] += (centerY - py) * gravityStrength;
    }

    // 5. Update Velocities & Coordinate Positions
    double maxVelocity = 0.0;
    final pinnedNodeIds = widget.nodes.where((n) => n.isPinned).map((n) => n.id).toSet();

    for (int i = 0; i < n; i++) {
      final id = widget.nodes[i].id;
      final double opacity = _isReplaying ? (_nodeOpacities[id] ?? 0.0) : 1.0;

      if (opacity <= 0.0) {
        _flatVelocities![2 * i] = 0.0;
        _flatVelocities![2 * i + 1] = 0.0;
        continue;
      }

      if (id == _draggedNodeId) continue; // Dragged node stays pinned under user's finger!

      if (pinnedNodeIds.contains(id)) {
        _flatVelocities![2 * i] = 0.0;
        _flatVelocities![2 * i + 1] = 0.0;
        continue;
      }

      final double fx = _flatForces![2 * i];
      final double fy = _flatForces![2 * i + 1];
      final double vx = _flatVelocities![2 * i];
      final double vy = _flatVelocities![2 * i + 1];

      // Sanity check force and velocity
      if (!fx.isFinite || !fy.isFinite || !vx.isFinite || !vy.isFinite) {
        _flatVelocities![2 * i] = 0.0;
        _flatVelocities![2 * i + 1] = 0.0;
        _flatPositions![2 * i] = centerX;
        _flatPositions![2 * i + 1] = centerY;
        continue;
      }

      // Euler Integration: velocity = (velocity + force) * damping
      double newVx = (vx + fx) * widget.damping;
      double newVy = (vy + fy) * widget.damping;

      // Clamp speed to prevent numeric explosion (cosmic safety limit)
      final double speed = sqrt(newVx * newVx + newVy * newVy);
      const double maxSpeed = 16.0;
      if (speed > maxSpeed) {
        newVx = (newVx / speed) * maxSpeed;
        newVy = (newVy / speed) * maxSpeed;
      }

      double finalX = _flatPositions![2 * i] + newVx;
      double finalY = _flatPositions![2 * i + 1] + newVy;

      // Validate positions are finite
      if (!finalX.isFinite || !finalY.isFinite) {
        finalX = centerX;
        finalY = centerY;
        newVx = 0.0;
        newVy = 0.0;
      }

      // Clamp to canvas boundaries and zero matching velocity components
      if (finalX < 50.0) {
        finalX = 50.0;
        newVx = 0.0;
      } else if (finalX > 4950.0) {
        finalX = 4950.0;
        newVx = 0.0;
      }

      if (finalY < 40.0) {
        finalY = 40.0;
        newVy = 0.0;
      } else if (finalY > 4960.0) {
        finalY = 4960.0;
        newVy = 0.0;
      }

      _flatVelocities![2 * i] = newVx;
      _flatVelocities![2 * i + 1] = newVy;
      _flatPositions![2 * i] = finalX;
      _flatPositions![2 * i + 1] = finalY;

      final double currentSpeed = sqrt(newVx * newVx + newVy * newVy);
      if (currentSpeed > maxVelocity) {
        maxVelocity = currentSpeed;
      }
    }

    // Sync the flat array back to the position coordinate map once at the end of the tick
    for (int i = 0; i < n; i++) {
      final id = widget.nodes[i].id;
      _positions[id] = Offset(_flatPositions![2 * i], _flatPositions![2 * i + 1]);
      _velocities[id] = Offset(_flatVelocities![2 * i], _flatVelocities![2 * i + 1]);
    }

    _repaintNotifier.notify();

    // Check if the simulation has cooled down to rest
    if (!_isReplaying && _draggedNodeId == null && maxVelocity < 0.05) {
      _ticker.stop();
      for (final id in _velocities.keys) {
        _velocities[id] = Offset.zero;
      }

      final autoFitPerformed = ref.read(graphAutoFitPerformedProvider);
      if (!autoFitPerformed) {
        fitToContent();
        ref.read(graphAutoFitPerformedProvider.notifier).state = true;
      }
    }
  }

  void fitToContent({bool animate = true}) {
    if (!mounted || _positions.isEmpty) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final pos in _positions.values) {
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dx > maxX) maxX = pos.dx;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dy > maxY) maxY = pos.dy;
    }

    final width = maxX - minX + 200.0;
    final height = maxY - minY + 200.0;
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    final size = MediaQuery.of(context).size;
    final viewWidth = size.width > 0 ? size.width : 400.0;
    final viewHeight = size.height > 0 ? size.height : 300.0;

    final scaleX = viewWidth / width;
    final scaleY = viewHeight / height;
    final scale = min(scaleX, scaleY).clamp(0.15, 1.5);

    final tx = viewWidth / 2 - centerX * scale;
    final ty = viewHeight / 2 - centerY * scale;

    final targetMatrix = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, scale, 1.0);

    if (animate) {
      _viewportAnimationController?.stop();
      final currentMatrix = widget.transformationController.value;
      _viewportAnimation = Matrix4Tween(
        begin: currentMatrix,
        end: targetMatrix,
      ).animate(CurvedAnimation(
        parent: _viewportAnimationController!,
        curve: Curves.easeInOutCubic,
      ));
      _viewportAnimationController?.forward(from: 0.0);
    } else {
      widget.transformationController.value = targetMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warm up settings provider to ensure it's loaded during interaction
    final _ = ref.watch(dragToPinEnabledProvider);

    ref.listen<AsyncValue<Map<String, String?>>>(graphNodeColorsProvider, (prev, next) {
      final resolvedColors = next.valueOrNull ?? const {};
      _buildNodeContentCache(resolvedColors);
      setState(() {});
    });

    if (_nodeContentCache.isEmpty) {
      final resolvedColors = ref.read(graphNodeColorsProvider).valueOrNull ?? const {};
      _buildNodeContentCache(resolvedColors);
    }

    final colorScheme = Theme.of(context).colorScheme;
    const canvasWidth = 5000.0;
    const canvasHeight = 5000.0;

    Widget graphContent = InteractiveViewer(
      transformationController: widget.transformationController,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.1,
      maxScale: 3.0,
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: Stack(
          children: [
            // 1. Draw connecting elastic lines (Custom Paint background)
            Positioned.fill(
              child: CustomPaint(
                painter: GraphLinksPainter(
                  positions: _positions,
                  edges: widget.edges,
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  ghostNodeIds: widget.nodes.where((n) => n.isGhost).map((n) => n.id).toSet(),
                  nodeOpacities: _nodeOpacities,
                  isReplaying: _isReplaying,
                  repaint: _repaintNotifier,
                ),
              ),
            ),

            // 2. Draw interactive node widgets (Positioned using Flow layout)
            Positioned.fill(
              child: Flow(
                delegate: GraphFlowDelegate(
                  positions: _positions,
                  nodes: widget.nodes,
                  repaint: _repaintNotifier,
                ),
                children: widget.nodes.map((gn) {
                  return GestureDetector(
                    key: ValueKey('drag_${gn.id}'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      _draggedNodeId = gn.id;
                      _wakeSimulation();
                    },
                    onPanUpdate: (details) {
                      final delta = details.delta;
                      final newX = ((_positions[gn.id]?.dx ?? 0.0) + delta.dx).clamp(50.0, 4950.0);
                      final newY = ((_positions[gn.id]?.dy ?? 0.0) + delta.dy).clamp(40.0, 4960.0);
                      _positions[gn.id] = Offset(newX, newY);
                      _velocities[gn.id] = Offset.zero;
                      _repaintNotifier.notify();
                    },
                    onPanEnd: (details) {
                      _draggedNodeId = null;
                      if (!mounted) return;
                      final finalPos = _positions[gn.id];
                      if (finalPos != null && !gn.isGhost && !gn.isTemporal) {
                        final dragToPin = ref.read(dragToPinEnabledProvider).valueOrNull ?? false;
                        if (dragToPin) {
                          ref.read(graphNodeRepositoryProvider).pinNode(gn.id, finalPos.dx, finalPos.dy);
                        } else {
                          if (gn.isPinned) {
                            ref.read(graphNodeRepositoryProvider).pinNode(gn.id, finalPos.dx, finalPos.dy);
                          }
                        }
                      }
                    },
                    child: SizedBox(
                      width: 100,
                      height: 80,
                      child: Transform.scale(
                        scale: _isReplaying
                            ? Curves.easeOutBack.transform(_nodeOpacities[gn.id] ?? 0.0)
                            : 1.0,
                        child: Opacity(
                          opacity: _isReplaying ? (_nodeOpacities[gn.id] ?? 0.0) : 1.0,
                          child: _nodeContentCache[gn.id] ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    // Play entry animation only once when GraphSimulationCanvas is first mounted
    if (!widget.disableEntranceAnimation && !_playedEntranceAnimation) {
      return graphContent
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
    }

    return graphContent;
  }
}

// ─── Custom Repaint Notifier class ──────────────────────────────────────────
class _RepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

// ─── Flow layout delegate for high-performance node positioning ──────────────
class GraphFlowDelegate extends FlowDelegate {
  final Map<String, Offset> positions;
  final List<GraphNode> nodes;
  final Listenable repaint;

  GraphFlowDelegate({
    required this.positions,
    required this.nodes,
    required this.repaint,
  }) : super(repaint: repaint);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tight(const Size(100.0, 80.0));
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final pos = positions[node.id];
      if (pos != null && pos.dx.isFinite && pos.dy.isFinite) {
        final double dotSize;
        if (node.isTemporal) {
          dotSize = node.temporalType == 'year' ? 20.0 : 10.0;
        } else {
          dotSize = (8.0 + (node.linkCount * 1.5).clamp(0.0, 12.0)).toDouble();
        }
        final dx = pos.dx - 50.0; // center on node width (100)
        final dy = pos.dy - (dotSize / 2);
        context.paintChild(
          i,
          transform: Matrix4.translationValues(dx, dy, 0.0),
        );
      } else {
        context.paintChild(i);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphFlowDelegate oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.nodes != nodes;
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return const Size(5000.0, 5000.0);
  }
}

// ─── Custom Spring-line painter for connected wikilink edges ────────────────
class GraphLinksPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<GraphEdge> edges;
  final Color color;
  final Set<String> ghostNodeIds;
  final Map<String, double> nodeOpacities;
  final bool isReplaying;

  GraphLinksPainter({
    required this.positions,
    required this.edges,
    required this.color,
    required this.ghostNodeIds,
    required this.nodeOpacities,
    required this.isReplaying,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final src = positions[edge.sourceId];
      final tgt = positions[edge.targetId];
      if (src != null && src.dx.isFinite && src.dy.isFinite &&
          tgt != null && tgt.dx.isFinite && tgt.dy.isFinite) {
        
        double edgeOpacity = 1.0;
        if (isReplaying) {
          final opacityA = nodeOpacities[edge.sourceId] ?? 0.0;
          final opacityB = nodeOpacities[edge.targetId] ?? 0.0;
          final minOpacity = min(opacityA, opacityB);
          
          if (minOpacity < 0.85) {
            continue; // Keep edge hidden until both nodes are mostly popped up
          }
          // Fade in the edge quickly from 0.0 to 1.0 as the minOpacity goes from 0.85 to 1.0
          edgeOpacity = ((minOpacity - 0.85) / 0.15).clamp(0.0, 1.0);
        }

        final isGhostConnection = ghostNodeIds.contains(edge.sourceId) || ghostNodeIds.contains(edge.targetId);
        final baseAlpha = isGhostConnection ? 0.15 : 0.35;
        final finalAlpha = baseAlpha * edgeOpacity;

        if (finalAlpha <= 0.001) continue;

        final edgePaint = Paint()
          ..color = color.withValues(alpha: finalAlpha)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(src, tgt, edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphLinksPainter oldDelegate) {
    return oldDelegate.positions != positions || 
           oldDelegate.edges != edges || 
           oldDelegate.color != color ||
           oldDelegate.ghostNodeIds != ghostNodeIds ||
           oldDelegate.nodeOpacities != nodeOpacities ||
           oldDelegate.isReplaying != isReplaying;
  }
}