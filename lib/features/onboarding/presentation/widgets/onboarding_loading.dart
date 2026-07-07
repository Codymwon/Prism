import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import 'package:prism/l10n/l10n.dart';

class OnboardingLoading extends StatelessWidget {
  const OnboardingLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
              semanticsLabel: 'Loading',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.onboarding_loading_title,
            style: DesignTypography.heading(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboarding_loading_description,
            style: DesignTypography.details(
              context,
              fontSize: 12,
              color: DesignColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}