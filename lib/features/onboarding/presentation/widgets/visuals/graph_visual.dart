import 'package:flutter/material.dart';
import '../../../../../shared/design_system/design_system.dart';

class GraphVisual extends StatefulWidget {
  const GraphVisual({super.key});

  @override
  State<GraphVisual> createState() => _GraphVisualState();
}

class _GraphVisualState extends State<GraphVisual> with TickerProviderStateMixin {
  late AnimationController _centerController;
  late AnimationController _topLeftController;
  late AnimationController _topRightController;
  late AnimationController _bottomLeftController;
  late AnimationController _bottomRightController;

  late Animation<double> _centerAnimation;
  late Animation<double> _topLeftAnimation;
  late Animation<double> _topRightAnimation;
  late Animation<double> _bottomLeftAnimation;
  late Animation<double> _bottomRightAnimation;

  @override
  void initState() {
    super.initState();
    _centerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _topLeftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _topRightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _bottomLeftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _bottomRightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _centerAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _centerController, curve: Curves.easeInOut),
    );

    _topLeftAnimation = Tween<double>(begin: 3, end: -3).animate(
      CurvedAnimation(parent: _topLeftController, curve: Curves.easeInOut),
    );

    _topRightAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _topRightController, curve: Curves.easeInOut),
    );

    _bottomLeftAnimation = Tween<double>(begin: -2, end: 4).animate(
      CurvedAnimation(parent: _bottomLeftController, curve: Curves.easeInOut),
    );

    _bottomRightAnimation = Tween<double>(begin: 4, end: -2).animate(
      CurvedAnimation(parent: _bottomRightController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _centerController.dispose();
    _topLeftController.dispose();
    _topRightController.dispose();
    _bottomLeftController.dispose();
    _bottomRightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    final border = DesignColors.border(context);
    final accentGreen = DesignColors.accentGreen(context);
    final accentAmber = DesignColors.accentAmber(context);

    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Connection lines underneath
          Positioned.fill(
            child: CustomPaint(
              painter: GraphLinesPainter(
                color: border,
                center: const Offset(110, 90),
                points: const [
                  Offset(40, 40),
                  Offset(180, 45),
                  Offset(50, 140),
                  Offset(170, 135),
                ],
              ),
            ),
          ),
          // Center Node
          AnimatedBuilder(
            animation: _centerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _centerAnimation.value),
                child: child,
              );
            },
            child: _buildGraphNode(context, 'Brain', Icons.lens_blur_rounded, primary, 28),
          ),
          // Top-Left Node
          Positioned(
            top: 25,
            left: 25,
            child: AnimatedBuilder(
              animation: _topLeftAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _topLeftAnimation.value),
                  child: child,
                );
              },
              child: _buildGraphNode(context, 'Journal', Icons.calendar_today_rounded, accentGreen, 20),
            ),
          ),
          // Top-Right Node
          Positioned(
            top: 30,
            right: 25,
            child: AnimatedBuilder(
              animation: _topRightAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _topRightAnimation.value),
                  child: child,
                );
              },
              child: _buildGraphNode(context, 'Work', Icons.work_outline_rounded, accentAmber, 20),
            ),
          ),
          // Bottom-Left Node
          Positioned(
            bottom: 25,
            left: 35,
            child: AnimatedBuilder(
              animation: _bottomLeftAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bottomLeftAnimation.value),
                  child: child,
                );
              },
              child: _buildGraphNode(context, 'Quotes', Icons.format_quote_rounded, Colors.purple, 20),
            ),
          ),
          // Bottom-Right Node
          Positioned(
            bottom: 20,
            right: 35,
            child: AnimatedBuilder(
              animation: _bottomRightAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bottomRightAnimation.value),
                  child: child,
                );
              },
              child: _buildGraphNode(context, 'Tasks', Icons.check_circle_outline_rounded, Colors.teal, 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphNode(BuildContext context, String label, IconData icon, Color color, double size) {
    final text = DesignColors.text(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(
            icon,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: DesignColors.surfaceVariant(context).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: DesignColors.border(context), width: 0.5),
          ),
          child: Text(
            label,
            style: DesignTypography.metadata(
              context,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ),
      ],
    );
  }
}

class GraphLinesPainter extends CustomPainter {
  final Color color;
  final Offset center;
  final List<Offset> points;

  GraphLinesPainter({
    required this.color,
    required this.center,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawLine(center, pt, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphLinesPainter oldDelegate) {
    if (oldDelegate.color != color || oldDelegate.center != center) {
      return true;
    }
    if (oldDelegate.points.length != points.length) {
      return true;
    }
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) {
        return true;
      }
    }
    return false;
  }
}
