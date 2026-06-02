import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../shared/design_system/design_system.dart';

class ProductivityVisual extends StatelessWidget {
  const ProductivityVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);
    final accentGreen = DesignColors.accentGreen(context);

    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mock keyboard/toolbar outline at bottom
          Positioned(
            bottom: 10,
            child: Container(
              width: 170,
              height: 48,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.format_bold_rounded, size: 14, color: DesignColors.textTertiary(context)),
                  Icon(Icons.format_italic_rounded, size: 14, color: DesignColors.textTertiary(context)),
                  Icon(Icons.link_rounded, size: 14, color: DesignColors.textTertiary(context)),
                  Container(width: 1, height: 20, color: border),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '📅 Date',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '☑️ Todo',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accentGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Glowing mic icon in the center
          Positioned(
            top: 15,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 32,
                color: Colors.white,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.08, 1.08), duration: 1200.ms, curve: Curves.easeInOut),
          ),
          // Decorative sound waves pulsing around mic
          Positioned(
            top: 24,
            left: 45,
            child: Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scaleY(begin: 0.6, end: 1.5, duration: 800.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            top: 24,
            right: 45,
            child: Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scaleY(begin: 0.4, end: 1.7, duration: 900.ms, curve: Curves.easeInOut),
          ),
          // Floating macro icon: 📝 Summary
          Positioned(
            top: 20,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text('Summary', style: DesignTypography.metadata(context, fontSize: 8.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: -4, end: 2, duration: 1500.ms, curve: Curves.easeInOut),
          ),
          // Floating macro icon: 🎯 Goal
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text('Goal', style: DesignTypography.metadata(context, fontSize: 8.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: 2, end: -4, duration: 1700.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}
