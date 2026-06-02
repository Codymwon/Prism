import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../shared/design_system/design_system.dart';

class PrivacyVisual extends StatelessWidget {
  const PrivacyVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);
    final surfaceVariant = DesignColors.surfaceVariant(context);
    final accentGreen = DesignColors.accentGreen(context);

    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Folder background shape
          Positioned(
            bottom: 10,
            child: Container(
              width: 140,
              height: 110,
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Folder tab
                  Positioned(
                    top: -9,
                    left: 12,
                    child: Container(
                      width: 45,
                      height: 10,
                      decoration: BoxDecoration(
                        color: surfaceVariant,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        border: Border(
                          top: BorderSide(color: border, width: 1.5),
                          left: BorderSide(color: border, width: 1.5),
                          right: BorderSide(color: border, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Document files falling in dynamically
          Positioned(
            top: 15,
            left: 60,
            child: _buildMiniDoc(context, 'notes.md', accentGreen)
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 1000.ms)
                .slideY(begin: -0.5, end: 0.5, duration: 1500.ms, curve: Curves.easeIn)
                .fadeOut(delay: 1100.ms, duration: 400.ms),
          ),
          Positioned(
            top: 5,
            right: 55,
            child: _buildMiniDoc(context, 'journal.md', primary)
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 1200.ms)
                .slideY(begin: -0.4, end: 0.6, duration: 1800.ms, delay: 400.ms, curve: Curves.easeIn)
                .fadeOut(delay: 1300.ms, duration: 500.ms),
          ),
          // Lock Overlay Badge
          Positioned(
            bottom: 35,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 32,
                color: primary,
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDoc(BuildContext context, String name, Color accent) {
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);

    return Container(
      width: 80,
      height: 45,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 10, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 6,
                  color: DesignColors.text(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(width: 50, height: 4, color: DesignColors.textSecondary(context).withValues(alpha: 0.3)),
          const SizedBox(height: 4),
          Container(width: 30, height: 4, color: DesignColors.textSecondary(context).withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
