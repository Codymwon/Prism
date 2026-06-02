import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/data/note_model.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../widgets/graph_settings_panel.dart';

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
  double _repulsionRate = 1.0;            // Repelling charge strength
  double _repulsionPercentage = 0.5;      // Controls Rest Length: restLength = 120 * (1 / (repulsionPercentage + 0.1))
  double _attractionRate = 0.35;          // Elastic spring stiffness
  double _damping = 0.85;                 // Simulation Friction / drag resistance

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
    const canvasWidth = 2500.0;
    const canvasHeight = 2500.0;
    final x = -(canvasWidth - size.width) / 2;
    final y = -(canvasHeight - size.height) / 2;
    _transformationController.value = Matrix4.translationValues(x, y, 0.0);
  }

  void _triggerReLayout() {
    _canvasKey.currentState?.triggerReLayout();
  }

  void _resetToDefaults() {
    setState(() {
      _repulsionRate = 1.0;
      _repulsionPercentage = 0.5;
      _attractionRate = 0.35;
      _damping = 0.85;
      _triggerReLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final graphAsync = ref.watch(graphDataProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, colorScheme),
            Expanded(
              child: graphAsync.when(
                data: (data) {
                  if (data.nodes.isEmpty || data.edges.isEmpty) {
                    return _buildEmptyState(isDark, colorScheme);
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
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Graph View',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Your connected ideas',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: DesignColors.textSecondary(context),
            ),
            onPressed: () {
              ref.invalidate(graphDataProvider);
            },
          ),
          IconButton(
            icon: Icon(
              _showSettings ? Icons.settings_rounded : Icons.settings_outlined,
              color: _showSettings 
                  ? colorScheme.primary 
                  : DesignColors.textSecondary(context),
            ),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 72,
            color: DesignColors.textTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No connections yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start linking notes with [[wikilinks]] and your graph will grow here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DesignColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

// ─── Continuous Spring-Physics Graph simulation viewport (isolated rebuilds!) ───
class GraphSimulationCanvas extends StatefulWidget {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final double repulsionRate;
  final double repulsionPercentage;
  final double attractionRate;
  final double damping;
  final TransformationController transformationController;

  const GraphSimulationCanvas({
    super.key,
    required this.nodes,
    required this.edges,
    required this.repulsionRate,
    required this.repulsionPercentage,
    required this.attractionRate,
    required this.damping,
    required this.transformationController,
  });

  @override
  State<GraphSimulationCanvas> createState() => GraphSimulationCanvasState();
}

class GraphSimulationCanvasState extends State<GraphSimulationCanvas> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _velocities = {};
  String? _draggedNodeId;
  String? _selectedNodeId;
  bool _playedEntranceAnimation = false;

  // Cache to store pre-built static subtrees of node widgets
  final Map<String, Widget> _nodeContentCache = {};
  int _physicsTick = 0;

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
    // If nodes changed, initialize positions for any new ones
    _initializePositions(widget.nodes);
    if (oldWidget.nodes != widget.nodes) {
      _nodeContentCache.clear();
    }
  }

  // Pre-builds static widget subtrees once
  void _buildNodeContentCache() {
    _nodeContentCache.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    for (final gn in widget.nodes) {
      final isSelected = _selectedNodeId == gn.id;
      _nodeContentCache[gn.id] = _buildNodeWidgetContent(
        context,
        gn.id,
        gn.title,
        gn.linkCount,
        isDark,
        colorScheme,
        isSelected,
        gn.colorHex,
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void triggerReLayout() {
    final rand = Random();
    const centerX = 1250.0;
    const centerY = 1250.0;
    
    setState(() {
      for (final node in widget.nodes) {
        final angle = rand.nextDouble() * 2 * pi;
        final radius = 50 + rand.nextDouble() * 150;
        _positions[node.id] = Offset(
          centerX + cos(angle) * radius,
          centerY + sin(angle) * radius,
        );
        _velocities[node.id] = Offset.zero;
      }
    });
  }

  void _initializePositions(List<GraphNode> nodes) {
    final rand = Random();
    const centerX = 1250.0;
    const centerY = 1250.0;

    for (final gn in nodes) {
      if (!_positions.containsKey(gn.id)) {
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

    const centerX = 1250.0;
    const centerY = 1250.0;

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

        final delta = posA - posB;
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
    setState(() {
      _physicsTick++;
      for (final id in _positions.keys) {
        if (id == _draggedNodeId) continue; // Dragged node stays pinned under user's finger!

        final force = forces[id]!;
        final vel = _velocities[id]!;

        // Euler Integration: velocity = (velocity + force) * damping
        var newVel = (vel + force) * widget.damping;

        // Clamp speed to prevent numeric explosion (cosmic safety limit)
        const maxSpeed = 16.0;
        if (newVel.distance > maxSpeed) {
          newVel = newVel / newVel.distance * maxSpeed;
        }

        _velocities[id] = newVel;
        _positions[id] = _positions[id]! + newVel;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_nodeContentCache.isEmpty) {
      _buildNodeContentCache();
    }

    final colorScheme = Theme.of(context).colorScheme;
    const canvasWidth = 2500.0;
    const canvasHeight = 2500.0;

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
                  physicsTick: _physicsTick,
                ),
              ),
            ),

            // 2. Draw interactive node widgets (Draggable positioned items)
            ...widget.nodes.map((gn) {
              final pos = _positions[gn.id];
              if (pos == null) return const SizedBox.shrink();

              // Calculate dot size to offset the vertical position perfectly
              final dotSize = (8.0 + (gn.linkCount * 1.5).clamp(0.0, 12.0)).toDouble();

              return Positioned(
                left: pos.dx - 40,
                top: pos.dy - (dotSize / 2),
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _draggedNodeId = gn.id;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      // Directly pin coordinate to user finger dragging
                      _positions[gn.id] = _positions[gn.id]! + details.delta;
                      _velocities[gn.id] = Offset.zero;
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _draggedNodeId = null;
                    });
                  },
                  child: SizedBox(
                    width: 80,
                    child: _nodeContentCache[gn.id] ?? const SizedBox.shrink(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );

    // Play entry animation only once when GraphSimulationCanvas is first mounted
    if (!_playedEntranceAnimation) {
      return graphContent
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
    }

    return graphContent;
  }

  String _pruneTitle(String title) {
    if (title.length > 15) {
      return '${title.substring(0, 12)}...';
    }
    return title;
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null) return null;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildNodeWidgetContent(
    BuildContext context,
    String id,
    String title,
    int linkCount,
    bool isDark,
    ColorScheme colorScheme,
    bool isSelected,
    String? colorHex,
  ) {
    final dotSize = (8.0 + (linkCount * 1.5).clamp(0.0, 12.0)).toDouble();
    final folderColor = _parseColor(colorHex);
    final defaultColor = (isDark ? Colors.grey[400] : Colors.grey[600]) ?? Colors.grey;
    final Color dotColor = isSelected 
        ? colorScheme.primary 
        : (folderColor ?? defaultColor);

    return TactileWrapper(
      onTap: () {
        setState(() {
          _selectedNodeId = id;
          _nodeContentCache.clear(); // Rebuild with selection highlights!
        });
        context.push('/editor/$id');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              _pruneTitle(title),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? colorScheme.primary 
                    : (isDark ? colorScheme.onSurface.withValues(alpha: 0.7) : colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Spring-line painter for connected wikilink edges ────────────────
class GraphLinksPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<GraphEdge> edges;
  final Color color;
  final int physicsTick;

  GraphLinksPainter({
    required this.positions,
    required this.edges,
    required this.color,
    required this.physicsTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final src = positions[edge.sourceId];
      final tgt = positions[edge.targetId];
      if (src != null && tgt != null) {
        canvas.drawLine(src, tgt, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphLinksPainter oldDelegate) {
    return oldDelegate.physicsTick != physicsTick || 
           oldDelegate.edges != edges || 
           oldDelegate.color != color;
  }
}
