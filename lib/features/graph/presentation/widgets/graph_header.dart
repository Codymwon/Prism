import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/design_system/design_system.dart';

class GraphHeader extends StatelessWidget {
  final bool showSettings;
  final VoidCallback onRefresh;
  final VoidCallback onSettingsToggle;

  const GraphHeader({
    super.key,
    required this.showSettings,
    required this.onRefresh,
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
                'Graph View',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? PrismColors.darkText : PrismColors.lightText,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Your connected ideas',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: DesignColors.textSecondary(context),
            ),
            onPressed: onRefresh,
          ),
          IconButton(
            icon: Icon(
              showSettings ? Icons.settings_rounded : Icons.settings_outlined,
              color: showSettings 
                  ? colorScheme.primary 
                  : DesignColors.textSecondary(context),
            ),
            onPressed: onSettingsToggle,
          ),
        ],
      ),
    );
  }
}
