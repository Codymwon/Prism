import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import 'package:prism/l10n/l10n.dart';

class GraphHeader extends StatelessWidget {
  final bool showSettings;
  final VoidCallback onReplay;
  final VoidCallback onFocusCenter;
  final VoidCallback onSettingsToggle;

  const GraphHeader({
    super.key,
    required this.showSettings,
    required this.onReplay,
    required this.onFocusCenter,
    required this.onSettingsToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.graph_header_title,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? PrismColors.darkText : PrismColors.lightText,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                context.l10n.graph_header_subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: context.l10n.graph_header_reset_tooltip,
            child: TactileWrapper(
              onTap: onFocusCenter,
              style: TactileFeedbackStyle.standard,
              semanticLabel: context.l10n.graph_header_reset_tooltip,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.transparent,
                child: Icon(
                  Icons.gps_fixed_rounded,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: context.l10n.graph_header_replay_tooltip,
            child: TactileWrapper(
              onTap: onReplay,
              style: TactileFeedbackStyle.standard,
              semanticLabel: context.l10n.graph_header_replay_tooltip,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.transparent,
                child: Icon(
                  Icons.play_circle_outline,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: context.l10n.graph_header_settings_tooltip,
            child: TactileWrapper(
              onTap: onSettingsToggle,
              style: TactileFeedbackStyle.standard,
              semanticLabel: context.l10n.graph_header_settings_tooltip,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.transparent,
                child: Icon(
                  showSettings ? Icons.settings_rounded : Icons.settings_outlined,
                  color: showSettings 
                      ? colorScheme.primary 
                      : DesignColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}