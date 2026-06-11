import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/graph_node_repository.dart';
import '../providers/graph_providers.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/data/note_model.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../widgets/graph_settings_panel.dart';
import '../widgets/graph_header.dart';
import '../widgets/graph_empty_state.dart';
import '../widgets/graph_node_widget.dart';
import '../../../settings/presentation/providers/settings_provider.dart';


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
    _transformationController = TransformationController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final graphAsync = ref.watch(graphDataProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            GraphHeader(
              showSettings: _showSettings,
              onRefresh: () => ref.invalidate(graphDataProvider),
              onSettingsToggle: () => setState(() => _showSettings = !_showSettings),
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
                        
                      // Floating Focus Center Button
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: TactileWrapper(
                          onTap: _centerView,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: DesignColors.surface(context)
                                  .withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DesignColors.border(context),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.gps_fixed_rounded,
                              size: 20,
                              color: DesignColors.text(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (graphAsync.hasError) {
                  return Center(child: Text('Error: ${graphAsync.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }(),
            ),
          ],
        ),
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

  // Cache to store pre-built static subtrees of node widgets
  final Map<String, Widget> _nodeContentCache = {};

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
    if (oldWidget.nodes != widget.nodes) {
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
  void _buildNodeContentCache() {
    _nodeContentCache.clear();
    for (final gn in widget.nodes) {
      final isSelected = _selectedNodeId == gn.id;
      _nodeContentCache[gn.id] = GraphNodeWidget(
        id: gn.id,
        title: gn.title,
        linkCount: gn.linkCount,
        isSelected: isSelected,
        colorHex: gn.colorHex,
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
    super.dispose();
  }

  void _wakeSimulation() {
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void triggerReLayout() {
    final rand = Random();
    const centerX = 2500.0;
    const centerY = 2500.0;
    
    for (final node in widget.nodes) {
      final angle = rand.nextDouble() * 2 * pi;
      final radius = 50 + rand.nextDouble() * 150;
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
    final rand = Random();
    const centerX = 2500.0;
    const centerY = 2500.0;

    // Clean up orphaned node coordinates
    final validIds = nodes.map((n) => n.id).toSet();
    _positions.removeWhere((key, _) => !validIds.contains(key));
    _velocities.removeWhere((key, _) => !validIds.contains(key));

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
        final angle = rand.nextDouble() * 2 * pi;
        final radius = 50 + rand.nextDouble() * 150;
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

    const centerX = 2500.0;
    const centerY = 2500.0;

    // 1. Initialize forces vector
    final Map<String, Offset> forces = {
      for (final id in _positions.keys) id: Offset.zero
    };

    // 2. Coulomb Repulsion: push all nodes apart (n^2 complexity but fast for small sets)
    final keys = _positions.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final idA = keys[i];
      final posA = _positions[idA];
      if (posA == null) continue;
      for (int j = i + 1; j < keys.length; j++) {
        final idB = keys[j];
        final posB = _positions[idB];
        if (posB == null) continue;

        var delta = posA - posB;
        if (delta == Offset.zero) {
          final rand = Random();
          final angle = rand.nextDouble() * 2 * pi;
          delta = Offset(cos(angle) * 0.1, sin(angle) * 0.1);
        }
        final distance = delta.distance + 0.1; // division by zero safety

        if (distance < 500.0) { // Repelling cutoff range
          // Coulomb Force = (ChargeStrength) / dist^2
          final forceMagnitude = (widget.repulsionRate * 12000.0) / (distance * distance);
          final forceVector = delta / distance * forceMagnitude;

          forces[idA] = forces[idA]! + forceVector;
          forces[idB] = forces[idB]! - forceVector;
        }
      }
    }

    // 3. Hooke Spring Attraction: pull connected nodes together
    for (final edge in widget.edges) {
      final idA = edge.sourceId;
      final idB = edge.targetId;

      final posA = _positions[idA];
      final posB = _positions[idB];

      if (posA != null && posB != null) {
        final delta = posB - posA;
        final distance = delta.distance + 0.1;

        // Dynamic Rest Length based on slider
        final restLength = 120.0 * (1.0 / (widget.repulsionPercentage + 0.1));
        final displacement = distance - restLength;
        
        // Elastic Force = stiffness * displacement
        final forceMagnitude = widget.attractionRate * 0.12 * displacement;
        final forceVector = delta / distance * forceMagnitude;

        forces[idA] = forces[idA]! + forceVector;
        forces[idB] = forces[idB]! - forceVector;
      }
    }

    // 4. Center Gravity Force: keep nodes centered in viewport
    const gravityStrength = 0.008;
    for (final id in _positions.keys) {
      final pos = _positions[id]!;
      final delta = Offset(centerX, centerY) - pos;
      forces[id] = forces[id]! + delta * gravityStrength;
    }

    // 5. Update Velocities & Coordinate Positions
    double maxVelocity = 0.0;
    final pinnedNodeIds = widget.nodes.where((n) => n.isPinned).map((n) => n.id).toSet();

    for (final id in _positions.keys) {
      if (id == _draggedNodeId) continue; // Dragged node stays pinned under user's finger!

      if (pinnedNodeIds.contains(id)) {
        _velocities[id] = Offset.zero;
        continue;
      }

      final force = forces[id]!;
      final vel = _velocities[id]!;

      // Sanity check force and velocity
      if (!force.dx.isFinite || !force.dy.isFinite ||
          !vel.dx.isFinite || !vel.dy.isFinite) {
        _velocities[id] = Offset.zero;
        _positions[id] = const Offset(centerX, centerY);
        continue;
      }

      // Euler Integration: velocity = (velocity + force) * damping
      var newVel = (vel + force) * widget.damping;

      // Clamp speed to prevent numeric explosion (cosmic safety limit)
      const maxSpeed = 16.0;
      if (newVel.distance > maxSpeed) {
        newVel = newVel / newVel.distance * maxSpeed;
      }

      var newPos = _positions[id]! + newVel;

      // Validate positions are finite
      if (!newPos.dx.isFinite || !newPos.dy.isFinite) {
        newPos = const Offset(centerX, centerY);
        newVel = Offset.zero;
      }

      // Clamp to canvas boundaries and zero matching velocity components
      double finalX = newPos.dx;
      double finalY = newPos.dy;

      if (finalX < 50.0) {
        finalX = 50.0;
        newVel = Offset(0.0, newVel.dy);
      } else if (finalX > 4950.0) {
        finalX = 4950.0;
        newVel = Offset(0.0, newVel.dy);
      }

      if (finalY < 40.0) {
        finalY = 40.0;
        newVel = Offset(newVel.dx, 0.0);
      } else if (finalY > 4960.0) {
        finalY = 4960.0;
        newVel = Offset(newVel.dx, 0.0);
      }

      _velocities[id] = newVel;
      _positions[id] = Offset(finalX, finalY);

      final speed = newVel.distance;
      if (speed > maxVelocity) {
        maxVelocity = speed;
      }
    }

    _repaintNotifier.notify();

    // Check if the simulation has cooled down to rest
    if (_draggedNodeId == null && maxVelocity < 0.05) {
      _ticker.stop();
      for (final id in _velocities.keys) {
        _velocities[id] = Offset.zero;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warm up settings provider to ensure it's loaded during interaction
    final _ = ref.watch(dragToPinEnabledProvider);

    if (_nodeContentCache.isEmpty) {
      _buildNodeContentCache();
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
                    onPanStart: gn.isTemporal ? null : (details) {
                      _draggedNodeId = gn.id;
                      _wakeSimulation();
                    },
                    onPanUpdate: gn.isTemporal ? null : (details) {
                      final delta = details.delta;
                      final newX = ((_positions[gn.id]?.dx ?? 0.0) + delta.dx).clamp(50.0, 4950.0);
                      final newY = ((_positions[gn.id]?.dy ?? 0.0) + delta.dy).clamp(40.0, 4960.0);
                      _positions[gn.id] = Offset(newX, newY);
                      _velocities[gn.id] = Offset.zero;
                      _repaintNotifier.notify();
                    },
                    onPanEnd: gn.isTemporal ? null : (details) {
                      _draggedNodeId = null;
                      if (!mounted) return;
                      final finalPos = _positions[gn.id];
                      if (finalPos != null && !gn.isGhost) {
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
                      child: _nodeContentCache[gn.id] ?? const SizedBox.shrink(),
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
        final dotSize = (8.0 + (node.linkCount * 1.5).clamp(0.0, 12.0)).toDouble();
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

  GraphLinksPainter({
    required this.positions,
    required this.edges,
    required this.color,
    required this.ghostNodeIds,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final src = positions[edge.sourceId];
      final tgt = positions[edge.targetId];
      if (src != null && src.dx.isFinite && src.dy.isFinite &&
          tgt != null && tgt.dx.isFinite && tgt.dy.isFinite) {
        final isGhostConnection = ghostNodeIds.contains(edge.sourceId) || ghostNodeIds.contains(edge.targetId);
        
        final finalAlpha = isGhostConnection ? 0.15 : 0.35;

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
           oldDelegate.ghostNodeIds != ghostNodeIds;
  }
}
