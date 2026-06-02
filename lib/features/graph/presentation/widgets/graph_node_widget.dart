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

  const GraphNodeWidget({
    super.key,
    required this.id,
    required this.title,
    required this.linkCount,
    required this.isSelected,
    required this.colorHex,
    required this.onTap,
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
    
    final dotSize = (8.0 + (linkCount * 1.5).clamp(0.0, 12.0)).toDouble();
    final folderColor = _parseColor(colorHex);
    final defaultColor = (isDark ? Colors.grey[400] : Colors.grey[600]) ?? Colors.grey;
    final Color dotColor = isSelected 
        ? colorScheme.primary 
        : (folderColor ?? defaultColor);

    return TactileWrapper(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
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
            ),
          ),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              _pruneTitle(title),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? colorScheme.primary 
                    : (isDark ? colorScheme.onSurface.withValues(alpha: 0.7) : colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
