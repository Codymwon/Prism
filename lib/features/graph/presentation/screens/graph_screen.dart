import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:graphview/GraphView.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/data/note_model.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';


class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  final Graph _graph = Graph()..isTree = false;
  final FruchtermanReingoldAlgorithm _algorithm = FruchtermanReingoldAlgorithm(
    FruchtermanReingoldConfiguration(
      iterations: 150,
      repulsionRate: 0.25,
      repulsionPercentage: 0.4,
      attractionRate: 0.15,
    ),
  );

  final Map<String, Node> _nodeMap = {};
  bool _isBuilt = false;
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
  }

  void _rebuildGraph(({List<GraphNode> nodes, List<GraphEdge> edges}) data) {
    _graph.nodes.clear();
    _graph.edges.clear();
    _nodeMap.clear();

    for (final gn in data.nodes) {
      final node = Node.Id(gn.id);
      _nodeMap[gn.id] = node;
      _graph.addNode(node);
    }

    for (final edge in data.edges) {
      final src = _nodeMap[edge.sourceId];
      final tgt = _nodeMap[edge.targetId];
      if (src != null && tgt != null) {
        _graph.addEdge(src, tgt);
      }
    }

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
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
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
                  return _buildGraphView(context, isDark, colorScheme, data);
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
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
            ),
            onPressed: () {
              ref.invalidate(graphDataProvider);
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
    final nodeMap = {for (final n in data.nodes) n.id: n};

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.3,
      maxScale: 3.0,
      child: GraphView(
        graph: _graph,
        algorithm: _algorithm,
        paint: Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.35)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final id = node.key!.value as String;
          final graphNode = nodeMap[id];
          final isSelected = _selectedNodeId == id;
          return _buildNodeWidget(
            context,
            id,
            graphNode?.title ?? id,
            graphNode?.linkCount ?? 0,
            isDark,
            colorScheme,
            isSelected,
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  String _pruneTitle(String title) {
    if (title.length > 15) {
      return '${title.substring(0, 12)}...';
    }
    return title;
  }

  Widget _buildNodeWidget(
    BuildContext context,
    String id,
    String title,
    int linkCount,
    bool isDark,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    final dotSize = (8.0 + (linkCount * 1.5).clamp(0.0, 12.0)).toDouble();

    return TactileWrapper(
      onTap: () {
        setState(() => _selectedNodeId = id);
        _showNodeSheet(context, id, title, isDark, colorScheme);
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
              color: isSelected 
                  ? colorScheme.primary 
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.5),
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

  void _showNodeSheet(
    BuildContext context,
    String id,
    String title,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: Text('Open note', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/editor/$id');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
            color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No connections yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start linking notes with [[wikilinks]] and your graph will grow here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
