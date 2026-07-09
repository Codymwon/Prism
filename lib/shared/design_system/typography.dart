import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DesignTypography {
  static String _resolveFontFamily(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Inter';
    if (family.contains('Lora')) return 'Lora';
    if (family.contains('Merriweather')) return 'Merriweather';
    if (family.contains('RobotoMono') || family.contains('Roboto Mono')) return 'RobotoMono';
    return 'Inter';
  }

  static TextStyle _getFont(BuildContext context, {required double fontSize, required FontWeight fontWeight, required Color color, double? height, double? letterSpacing}) {
    final family = _resolveFontFamily(context);
    switch (family) {
      case 'Lora':
        return GoogleFonts.lora(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height, letterSpacing: letterSpacing);
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height, letterSpacing: letterSpacing);
      case 'RobotoMono':
        return GoogleFonts.robotoMono(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height, letterSpacing: letterSpacing);
      case 'Inter':
      default:
        return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height, letterSpacing: letterSpacing);
    }
  }

  static TextStyle display(BuildContext context, {double fontSize = 28, FontWeight fontWeight = FontWeight.w700, Color? color}) {
    final fontColor = color ?? DesignColors.text(context);
    return _getFont(context, fontSize: fontSize, fontWeight: fontWeight, color: fontColor, letterSpacing: -0.5);
  }

  static TextStyle heading(BuildContext context, {double fontSize = 18, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    final fontColor = color ?? DesignColors.text(context);
    return _getFont(context, fontSize: fontSize, fontWeight: fontWeight, color: fontColor);
  }

  static TextStyle body(BuildContext context, {double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color? color, double height = 1.6}) {
    final fontColor = color ?? DesignColors.text(context);
    return _getFont(context, fontSize: fontSize, fontWeight: fontWeight, color: fontColor, height: height);
  }

  static TextStyle details(BuildContext context, {double fontSize = 12, FontWeight fontWeight = FontWeight.w400, Color? color}) {
    final fontColor = color ?? DesignColors.textSecondary(context);
    return _getFont(context, fontSize: fontSize, fontWeight: fontWeight, color: fontColor);
  }

  static TextStyle metadata(BuildContext context, {double fontSize = 11, FontWeight fontWeight = FontWeight.w400, Color? color}) {
    final fontColor = color ?? DesignColors.textTertiary(context);
    return _getFont(context, fontSize: fontSize, fontWeight: fontWeight, color: fontColor);
  }

  static TextStyle mono({double fontSize = 13, Color? color, double? height, Color? backgroundColor}) {
    return GoogleFonts.robotoMono(fontSize: fontSize, color: color, height: height, backgroundColor: backgroundColor);
  }
}
