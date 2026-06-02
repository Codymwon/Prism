import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import 'visuals/privacy_visual.dart';
import 'visuals/wikilinks_visual.dart';
import 'visuals/graph_visual.dart';
import 'visuals/journal_visual.dart';
import 'visuals/themes_visual.dart';
import 'visuals/productivity_visual.dart';

class OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String visualType;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.visualType,
  });
}

class OnboardingSlideView extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideView({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Theme-Aware Animated Visual Box
          Container(
            width: double.infinity,
            height: 200,
            alignment: Alignment.center,
            child: _buildVisual(slide.visualType),
          ),
          const SizedBox(height: 48),

          // Subtitle (curated sub-brand)
          Text(
            slide.subtitle.toUpperCase(),
            style: DesignTypography.metadata(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DesignColors.primary(context),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),

          // Main Title
          Text(
            slide.title,
            style: DesignTypography.display(
              context,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: DesignColors.text(context),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: DesignTypography.body(
              context,
              fontSize: 14,
              height: 1.6,
              color: DesignColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildVisual(String type) {
    switch (type) {
      case 'privacy':
        return const PrivacyVisual();
      case 'wikilinks':
        return const WikilinksVisual();
      case 'graph':
        return const GraphVisual();
      case 'journal':
        return const JournalVisual();
      case 'themes':
        return const ThemesVisual();
      case 'productivity':
        return const ProductivityVisual();
      default:
        return const SizedBox.shrink();
    }
  }
}
