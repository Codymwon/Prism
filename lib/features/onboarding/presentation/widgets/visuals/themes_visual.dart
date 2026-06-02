import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThemesVisual extends StatelessWidget {
  const ThemesVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom Card: Clean Paper (Light theme style)
          Positioned(
            left: 15,
            top: 45,
            child: _buildThemeMockCard(
              context: context,
              title: 'Clean Paper',
              bgColor: const Color(0xFFF9F6F0),
              textColor: const Color(0xFF2C2C2C),
              borderColor: const Color(0xFFE6DED4),
              tagBgColor: const Color(0xFFEBE5DC),
              fontFamily: 'Inter',
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: 0, end: -8, duration: 2500.ms, curve: Curves.easeInOut),
          ),
          // Middle Card: Midnight OLED (Dark theme style)
          Positioned(
            right: 15,
            top: 30,
            child: _buildThemeMockCard(
              context: context,
              title: 'Midnight OLED',
              bgColor: const Color(0xFF0C0C0C),
              textColor: const Color(0xFFECECEC),
              borderColor: const Color(0xFF222222),
              tagBgColor: const Color(0xFF1E1E1E),
              fontFamily: 'JetBrains Mono',
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: 0, end: 8, duration: 2500.ms, curve: Curves.easeInOut),
          ),
          // Top Card: Warm Sepia (Sepia theme style)
          Positioned(
            top: 15,
            child: _buildThemeMockCard(
              context: context,
              title: 'Warm Sepia',
              bgColor: const Color(0xFFFAF5EC),
              textColor: const Color(0xFF433422),
              borderColor: const Color(0xFFE8DEC9),
              tagBgColor: const Color(0xFFF3EAD5),
              fontFamily: 'Lora',
              shadowColor: Colors.black.withValues(alpha: 0.1),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 2000.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeMockCard({
    required BuildContext context,
    required String title,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required Color tagBgColor,
    required String fontFamily,
    Color? shadowColor,
  }) {
    return Container(
      width: 120,
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            title,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          // Horizontal mock text lines
          Container(width: 80, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(width: 95, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(width: 60, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          // Tag pills
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#writing',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#ideas',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
