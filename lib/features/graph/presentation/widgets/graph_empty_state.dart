import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';
import 'package:prism/l10n/l10n.dart';

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
            context.l10n.graph_empty_state_title,
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
              context.l10n.graph_empty_state_description,
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