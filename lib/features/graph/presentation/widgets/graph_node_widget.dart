import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';

class GraphNodeWidget extends StatelessWidget {
  final String id;
  final String title;
  final int linkCount;
  final bool isSelected;
  final String? colorHex;
  final VoidCallback onTap;
  final bool isTemporal;
  final String? temporalType;
  final bool isGhost;

  const GraphNodeWidget({
    super.key,
    required this.id,
    required this.title,
    required this.linkCount,
    required this.isSelected,
    required this.colorHex,
    required this.onTap,
    this.isTemporal = false,
    this.temporalType,
    this.isGhost = false,
  });

  String _pruneTitle(String title) {
    if (title.length > 15) {
      return '${title.substring(0, 12)}...';
    }
    return title;
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null) return null;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    final folderColor = _parseColor(colorHex);
    final defaultColor = (isDark ? Colors.grey[400] : Colors.grey[600]) ?? Colors.grey;
    
    final double dotSize;
    final BoxDecoration boxDecoration;
    final Color baseDotColor = isSelected 
        ? colorScheme.primary 
        : (folderColor ?? defaultColor);
    final Color dotColor = isGhost 
        ? baseDotColor.withValues(alpha: 0.35) 
        : baseDotColor;

    if (isTemporal) {
      final Color tempColor = colorScheme.primary;
      if (temporalType == 'year') {
        dotSize = 20.0;
        boxDecoration = BoxDecoration(
          shape: BoxShape.circle,
          color: tempColor,
        );
      } else {
        // week
        dotSize = 10.0;
        boxDecoration = BoxDecoration(
          shape: BoxShape.circle,
          color: tempColor,
        );
      }
    } else {
      dotSize = (8.0 + (linkCount * 1.5).clamp(0.0, 12.0)).toDouble();
      boxDecoration = BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      );
    }

    final childWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: dotSize,
          height: dotSize,
          decoration: boxDecoration,
        ),
        const SizedBox(height: 5),
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            _pruneTitle(title),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSelected || isTemporal ? FontWeight.w700 : FontWeight.w500,
              color: isSelected 
                  ? (isGhost ? colorScheme.primary.withValues(alpha: 0.35) : colorScheme.primary)
                  : (isDark 
                      ? colorScheme.onSurface.withValues(alpha: isGhost ? 0.3 : 0.7) 
                      : colorScheme.onSurface.withValues(alpha: isGhost ? 0.35 : 0.8)),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isTemporal) {
      return childWidget;
    }

    return TactileWrapper(
      onTap: onTap,
      child: childWidget,
    );
  }
}
