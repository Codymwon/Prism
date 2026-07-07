import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';

class GraphEmptyState extends StatelessWidget {
  const GraphEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 72,
            color: DesignColors.textTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No connections yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start linking notes with [[wikilinks]] and your graph will grow here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DesignColors.textSecondary(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
