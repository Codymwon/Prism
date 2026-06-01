import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:graphview/GraphView.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/data/note_model.dart';

class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  final Graph _graph = Graph()..isTree = false;
  final FruchtermanReingoldAlgorithm _algorithm = FruchtermanReingoldAlgorithm(
    FruchtermanReingoldConfiguration(
      iterations: 300,
      repulsionRate: 0.5,
      repulsionPercentage: 0.45,
      attractionRate: 0.1,
    ),
  );

  Map<String, Node> _nodeMap = {};
  bool _isBuilt = false;
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _buildGraph();
  }

  Future<void> _buildGraph() async {
    final data = await ref.read(graphDataProvider.future);
    _nodeMap = {};

    for (final gn in data.nodes) {
      final node = Node.Id(gn.id);
      _nodeMap[gn.id] = node;
      _graph.addNode(node);
    }

    for (final edge in data.edges) {
      final src = _nodeMap[edge.sourceId];
      final tgt = _nodeMap[edge.targetId];
      if (src != null && tgt != null) {
        _graph.addEdge(src, tgt, paint: Paint()..color = Colors.transparent);
      }
    }

    if (mounted) setState(() => _isBuilt = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final graphAsync = ref.watch(graphDataProvider);

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
              setState(() => _isBuilt = false);
              _graph.nodes.clear();
              _graph.edges.clear();
              _buildGraph();
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
          ..color = (isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder)
          ..strokeWidth = 1.0
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
    ).animate().fadeIn(duration: 500.ms);
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
    final size = (36.0 + (linkCount * 4).clamp(0, 24)).toDouble();

    return GestureDetector(
      onTap: () {
        setState(() => _selectedNodeId = id);
        _showNodeSheet(context, id, title, isDark, colorScheme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
              fontSize: (size * 0.38).clamp(10, 16),
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          ),
        ),
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
