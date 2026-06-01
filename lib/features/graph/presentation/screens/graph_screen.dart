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

class _GraphScreenContentState extends ConsumerState<GraphScreenContent> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late Ticker _ticker;

  // Settings panel toggle
  bool _showSettings = false;

  // Simulation physics parameters (Obsidian-Style)
  double _repulsionRate = 1.0;            // Repelling charge strength
  double _repulsionPercentage = 0.5;      // Controls Rest Length: restLength = 120 * (1 / (repulsionPercentage + 0.1))
  double _attractionRate = 0.35;          // Elastic spring stiffness
  double _damping = 0.85;                 // Simulation Friction / drag resistance

  // Node simulation coordinates
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _velocities = {};
  String? _draggedNodeId;

  // Keep track of active graph data
  List<GraphNode> _currentNodes = [];
  List<GraphEdge> _currentEdges = [];
  bool _isBuilt = false;
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // Setup spring-physics simulation frame loop
    _ticker = createTicker(_tick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
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

  void _triggerReLayout() {
    // Distribute nodes randomly near center again to settle
    final rand = Random();
    const centerX = 1250.0;
    const centerY = 1250.0;
    
    setState(() {
      for (final node in _currentNodes) {
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

  void _resetToDefaults() {
    setState(() {
      _repulsionRate = 1.0;
      _repulsionPercentage = 0.5;
      _attractionRate = 0.35;
      _damping = 0.85;
      _triggerReLayout();
    });
  }

  void _tick(Duration elapsed) {
    if (!mounted || _positions.isEmpty || _currentNodes.isEmpty) return;

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
      final posA = _positions[idA]!;
      for (int j = i + 1; j < keys.length; j++) {
        final idB = keys[j];
        final posB = _positions[idB]!;

        final delta = posA - posB;
        final distance = delta.distance + 0.1; // division by zero safety

        if (distance < 500.0) { // Repelling cutoff range
          // Coulomb Force = (ChargeStrength) / dist^2
          final forceMagnitude = (_repulsionRate * 12000.0) / (distance * distance);
          final forceVector = delta / distance * forceMagnitude;

          forces[idA] = forces[idA]! + forceVector;
          forces[idB] = forces[idB]! - forceVector;
        }
      }
    }

    // 3. Hooke Spring Attraction: pull connected nodes together
    for (final edge in _currentEdges) {
      final idA = edge.sourceId;
      final idB = edge.targetId;

      final posA = _positions[idA];
      final posB = _positions[idB];

      if (posA != null && posB != null) {
        final delta = posB - posA;
        final distance = delta.distance + 0.1;

        // Dynamic Rest Length based on slider
        final restLength = 120.0 * (1.0 / (_repulsionPercentage + 0.1));
        final displacement = distance - restLength;
        
        // Elastic Force = stiffness * displacement
        final forceMagnitude = _attractionRate * 0.12 * displacement;
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
      for (final id in _positions.keys) {
        if (id == _draggedNodeId) continue; // Dragged node stays pinned under user's finger!

        final force = forces[id]!;
        final vel = _velocities[id]!;

        // Euler Integration: velocity = (velocity + force) * damping
        var newVel = (vel + force) * _damping;

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

  void _rebuildGraph(({List<GraphNode> nodes, List<GraphEdge> edges}) data) {
    _initializePositions(data.nodes);
    _currentNodes = data.nodes;
    _currentEdges = data.edges;

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isBuilt = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final graphAsync = ref.watch(graphDataProvider);

    ref.listen(
      graphDataProvider,
      (previous, next) {
        next.whenOrNull(
          data: (data) {
            _rebuildGraph(data);
          },
        );
      },
    );

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
                  if (!_isBuilt) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Stack(
                    children: [
                      // Continuous Spring-Physics Graph simulation viewport
                      Positioned.fill(
                        child: _buildGraphView(context, isDark, colorScheme, data),
                      ),
                      
                      // Floating dynamic settings panel (Obsidian style)
                      if (_showSettings)
                        GraphSettingsPanel(
                          repulsionRate: _repulsionRate,
                          repulsionPercentage: _repulsionPercentage,
                          attractionRate: _attractionRate,
                          damping: _damping,
                          onChangedRepulsionRate: (val) => _repulsionRate = val,
                          onChangedRepulsionPercentage: (val) => _repulsionPercentage = val,
                          onChangedAttractionRate: (val) => _attractionRate = val,
                          onChangedDamping: (val) => _damping = val,
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
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
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

  Widget _buildGraphView(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    ({List<GraphNode> nodes, List<GraphEdge> edges}) data,
  ) {
    const canvasWidth = 2500.0;
    const canvasHeight = 2500.0;

    return InteractiveViewer(
      transformationController: _transformationController,
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
                  edges: _currentEdges,
                  color: colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
            ),

            // 2. Draw interactive node widgets (Draggable positioned items)
            ..._currentNodes.map((gn) {
              final pos = _positions[gn.id];
              if (pos == null) return const SizedBox.shrink();
              final isSelected = _selectedNodeId == gn.id;

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
                    child: _buildNodeWidget(
                      context,
                      gn.id,
                      gn.title,
                      gn.linkCount,
                      isDark,
                      colorScheme,
                      isSelected,
                      gn.colorHex,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
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

  Widget _buildNodeWidget(
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
        setState(() => _selectedNodeId = id);
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

// ─── Custom Spring-line painter for connected wikilink edges ────────────────
class GraphLinksPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<GraphEdge> edges;
  final Color color;

  GraphLinksPainter({
    required this.positions,
    required this.edges,
    required this.color,
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
    // Avoid redrawing unless positions, connections, or theme colors change
    return oldDelegate.positions != positions || 
           oldDelegate.edges != edges || 
           oldDelegate.color != color;
  }
}
