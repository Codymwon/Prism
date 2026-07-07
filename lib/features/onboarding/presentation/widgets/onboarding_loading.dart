import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';

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
            'Setting up Prism…',
            style: DesignTypography.heading(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparing onboarding guides and setting up workspace.',
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
