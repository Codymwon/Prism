import 'package:flutter/material.dart';

/// A CustomPainter that draws deterministic rounded vertical bars
/// representing the peaks of an audio file. Highlights the played
/// section in activeColor and the unplayed section in inactiveColor.
/// Optionally draws small triangular bookmark markers at specified
/// fractional positions along the waveform.
class WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress; // Range: 0.0 to 1.0
  final Color activeColor;
  final Color inactiveColor;
  final double barGap;
  /// Fractional positions (0.0–1.0) of bookmark markers to draw.
  final List<double> bookmarkPositions;
  final Color bookmarkColor;

  WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.barGap = 2.5,
    this.bookmarkPositions = const [],
    this.bookmarkColor = const Color(0xFFFFC107),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final paintActive = Paint()..color = activeColor..style = PaintingStyle.fill;
    final paintInactive = Paint()..color = inactiveColor..style = PaintingStyle.fill;

    final int count = peaks.length;
    final double totalGaps = barGap * (count - 1);
    final double barWidth = (size.width - totalGaps) / count;
    final double centerY = size.height / 2;
    
    // Fallback if calculated barWidth is too small
    final double effectiveBarWidth = barWidth > 0.5 ? barWidth : 2.0;

    for (int i = 0; i < count; i++) {
      final double peak = peaks[i];
      const double minHeight = 4.0;
      final double barHeight = minHeight + (peak * (size.height - minHeight));

      final double x = i * (effectiveBarWidth + barGap);
      final double top = centerY - (barHeight / 2);
      final double bottom = centerY + (barHeight / 2);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, top, x + effectiveBarWidth, bottom),
        Radius.circular(effectiveBarWidth / 2),
      );

      final double barFraction = count > 1 ? i / (count - 1) : 0.0;
      final bool isActive = barFraction <= progress;

      canvas.drawRRect(rect, isActive ? paintActive : paintInactive);
    }

    // Draw bookmark markers as small downward-pointing triangles at the top
    if (bookmarkPositions.isNotEmpty) {
      final bookmarkPaint = Paint()
        ..color = bookmarkColor
        ..style = PaintingStyle.fill;

      const double markerWidth = 8.0;
      const double markerHeight = 7.0;

      for (final fraction in bookmarkPositions) {
        final double x = fraction.clamp(0.0, 1.0) * size.width;
        // Draw a downward-pointing triangle at the top edge
        final path = Path()
          ..moveTo(x - markerWidth / 2, 0)
          ..lineTo(x + markerWidth / 2, 0)
          ..lineTo(x, markerHeight)
          ..close();
        canvas.drawPath(path, bookmarkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.barGap != barGap ||
        oldDelegate.bookmarkPositions != bookmarkPositions ||
        oldDelegate.bookmarkColor != bookmarkColor;
  }
}
