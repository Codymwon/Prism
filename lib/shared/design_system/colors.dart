import 'package:flutter/material.dart';

class DesignColors {
  static Color background(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).cardColor;
  static Color surfaceVariant(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color border(BuildContext context) => Theme.of(context).dividerColor;
  static Color text(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  
  static Color textSecondary(BuildContext context) => 
      Theme.of(context).textTheme.titleSmall?.color ?? 
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

  static Color textTertiary(BuildContext context) => 
      Theme.of(context).inputDecorationTheme.hintStyle?.color ?? 
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color accentRose(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color accentGreen(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accentAmber(BuildContext context) => Theme.of(context).colorScheme.tertiary;
}
