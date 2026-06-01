import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DesignColors {
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkBackground
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaBackground
            : MeridianColors.lightBackground);
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkSurface
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaSurface
            : MeridianColors.lightSurface);
  }

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkSurfaceVariant
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaSurfaceVariant
            : MeridianColors.lightSurfaceVariant);
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkBorder
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaBorder
            : MeridianColors.lightBorder);
  }

  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkText
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaText
            : MeridianColors.lightText);
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkTextSecondary
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaTextSecondary
            : MeridianColors.lightTextSecondary);
  }

  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkTextTertiary
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaTextTertiary
            : MeridianColors.lightTextTertiary);
  }

  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color accentRose(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkAccentRose
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaAccentRose
            : MeridianColors.lightAccentRose);
  }

  static Color accentGreen(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkAccentGreen
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaAccentGreen
            : MeridianColors.lightAccentGreen);
  }

  static Color accentAmber(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MeridianColors.darkAccentAmber
        : (Theme.of(context).colorScheme.primary == MeridianColors.sepiaPrimary
            ? MeridianColors.sepiaAccentAmber
            : MeridianColors.lightAccentAmber);
  }
}
