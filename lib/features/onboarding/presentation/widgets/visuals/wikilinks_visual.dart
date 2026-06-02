import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../shared/design_system/design_system.dart';

class WikilinksVisual extends StatelessWidget {
  const WikilinksVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    final border = DesignColors.border(context);
    final surfaceVariant = DesignColors.surfaceVariant(context);
    final accentGreen = DesignColors.accentGreen(context);

    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Note Card
          Positioned(
            left: 10,
            child: _buildInteractiveNoteCard(context, 'Ideas', Icons.lightbulb_outline_rounded, primary),
          ),
          // Right Note Card
          Positioned(
            right: 10,
            child: _buildInteractiveNoteCard(context, 'Brain Map', Icons.hub_outlined, accentGreen),
          ),
          // Double brackets floating & pulsing
          Positioned(
            top: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Text(
                '[[ wikilink ]]',
                style: DesignTypography.body(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          // Glowing connection beam
          Positioned(
            bottom: 45,
            left: 80,
            right: 80,
            child: SizedBox(
              height: 20,
              child: CustomPaint(
                painter: _BeamPainter(color: primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveNoteCard(BuildContext context, String title, IconData icon, Color color) {
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);

    return Container(
      width: 75,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: DesignTypography.heading(
              context,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(width: 40, height: 3, color: DesignColors.textSecondary(context).withValues(alpha: 0.2)),
          const SizedBox(height: 3),
          Container(width: 25, height: 3, color: DesignColors.textSecondary(context).withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  final Color color;
  _BeamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashWidth = 5.0;
    final dashSpace = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2), Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
