import 'package:flutter/material.dart';
import '../widgets/tactile_wrapper.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class DesignPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double? fontSize;

  const DesignPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 50.0,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final bg = isEnabled
        ? (backgroundColor ?? DesignColors.primary(context))
        : Colors.grey;
    final fg = isEnabled
        ? (foregroundColor ?? Colors.white)
        : Colors.white.withValues(alpha: 0.7);

    Widget buttonContent = Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: height * 0.36, color: fg),
              SizedBox(width: height * 0.16),
            ],
            Text(
              label,
              style: DesignTypography.heading(
                context,
                fontSize: fontSize ?? (height > 40 ? 15 : 13),
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );

    if (!isEnabled) {
      buttonContent = Opacity(
        opacity: 0.6,
        child: buttonContent,
      );
    }

    return TactileWrapper(
      onTap: onTap,
      style: TactileFeedbackStyle.highImpact,
      child: buttonContent,
    );
  }
}

class DesignSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const DesignSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? DesignColors.surfaceVariant(context) : DesignColors.surface(context);
    final border = DesignColors.border(context);
    final textStyle = DesignTypography.heading(
      context,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: DesignColors.text(context),
    );

    return TactileWrapper(
      onTap: onTap,
      style: TactileFeedbackStyle.standard,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: DesignColors.primary(context)),
              const SizedBox(width: 8),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}

class DesignFloatingActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const DesignFloatingActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = DesignColors.primary(context);

    return TactileWrapper(
      onTap: onTap,
      style: TactileFeedbackStyle.highImpact,
      child: FloatingActionButton.extended(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(
          label,
          style: DesignTypography.heading(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
