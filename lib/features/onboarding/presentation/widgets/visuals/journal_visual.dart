import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../shared/design_system/design_system.dart';

class JournalVisual extends StatelessWidget {
  const JournalVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);
    final surfaceVariant = DesignColors.surfaceVariant(context);
    final accentGreen = DesignColors.accentGreen(context);
    final accentAmber = DesignColors.accentAmber(context);

    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Journal Entry Card Mockup matching real screen
          Container(
            width: 140,
            height: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Streak header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Entry',
                      style: DesignTypography.heading(
                        context,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 6.5)),
                          const SizedBox(width: 1.5),
                          Text(
                            '3d',
                            style: DesignTypography.metadata(
                              context,
                              fontSize: 6.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Journal text mock lines
                Text(
                  '## 🙏 Gratitude',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(width: 110, height: 3.5, decoration: BoxDecoration(color: DesignColors.textSecondary(context).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 3),
                Container(width: 85, height: 3.5, decoration: BoxDecoration(color: DesignColors.textSecondary(context).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                // Word count progress goal mockup at the bottom
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '185 / 250 words',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '74%',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 6.5,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        height: 3.5,
                        width: double.infinity,
                        color: surfaceVariant,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 74,
                              child: Container(color: primary),
                            ),
                            const Expanded(
                              flex: 26,
                              child: SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating template bubbles around the main card
          Positioned(
            top: 15,
            left: 10,
            child: _buildFloatingBubble(context, '🙏', accentGreen)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -3, end: 3, duration: 1600.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: _buildFloatingBubble(context, '💭', accentAmber)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 3, end: -3, duration: 1400.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            top: 25,
            right: 15,
            child: _buildFloatingBubble(context, '🎯', const Color(0xFF8AB4F8))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -4, end: 4, duration: 1800.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: 25,
            right: 10,
            child: _buildFloatingBubble(context, '📋', primary)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 3, end: -3, duration: 1500.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBubble(BuildContext context, String emoji, Color color) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
