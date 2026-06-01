import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DesignTypography {
  static TextStyle display(BuildContext context, {double fontSize = 28, FontWeight fontWeight = FontWeight.w700, Color? color}) {
    final isSepia = Theme.of(context).colorScheme.primary.value == 0xFF5C3D2E;
    final fontColor = color ?? DesignColors.text(context);
    
    return isSepia
        ? GoogleFonts.lora(fontSize: fontSize, fontWeight: fontWeight, color: fontColor, letterSpacing: -0.5)
        : GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: fontColor, letterSpacing: -0.5);
  }

  static TextStyle heading(BuildContext context, {double fontSize = 18, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    final isSepia = Theme.of(context).colorScheme.primary.value == 0xFF5C3D2E;
    final fontColor = color ?? DesignColors.text(context);

    return isSepia
        ? GoogleFonts.lora(fontSize: fontSize, fontWeight: fontWeight, color: fontColor)
        : GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: fontColor);
  }

  static TextStyle body(BuildContext context, {double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color? color, double height = 1.6}) {
    final isSepia = Theme.of(context).colorScheme.primary.value == 0xFF5C3D2E;
    final fontColor = color ?? DesignColors.text(context);

    return isSepia
        ? GoogleFonts.merriweather(fontSize: fontSize, fontWeight: fontWeight, color: fontColor, height: height)
        : GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: fontColor, height: height);
  }

  static TextStyle details(BuildContext context, {double fontSize = 12, FontWeight fontWeight = FontWeight.w400, Color? color}) {
    final isSepia = Theme.of(context).colorScheme.primary.value == 0xFF5C3D2E;
    final fontColor = color ?? DesignColors.textSecondary(context);

    return isSepia
        ? GoogleFonts.merriweather(fontSize: fontSize, fontWeight: fontWeight, color: fontColor)
        : GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: fontColor);
  }

  static TextStyle metadata(BuildContext context, {double fontSize = 11, FontWeight fontWeight = FontWeight.w400, Color? color}) {
    final fontColor = color ?? DesignColors.textTertiary(context);
    return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: fontColor);
  }

  static TextStyle mono({double fontSize = 13, Color? color, double? height, Color? backgroundColor}) {
    return GoogleFonts.robotoMono(fontSize: fontSize, color: color, height: height, backgroundColor: backgroundColor);
  }
}
