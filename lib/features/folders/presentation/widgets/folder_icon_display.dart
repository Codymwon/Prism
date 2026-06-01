import 'package:flutter/material.dart';
import '../../../../shared/design_system/icons.dart';

/// A reusable folder icon with a color badge dot in the bottom-right corner.
///
/// [iconKey]   — DB-persisted string key resolved via [DesignIcons.resolveFolder].
/// [color]     — Accent color used for tinting the container/icon and the badge.
/// [size]      — Width/height of the outer container (default 44).
/// [badgeSize] — Diameter of the color badge dot (default 10).
class FolderIconDisplay extends StatelessWidget {
  final String iconKey;
  final Color color;
  final double size;
  final double badgeSize;
  final bool useThemedIcon;

  const FolderIconDisplay({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 44,
    this.badgeSize = 10,
    this.useThemedIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = DesignIcons.resolveFolder(iconKey);
    final iconSize = size * 0.52;
    final displayColor = useThemedIcon ? Theme.of(context).colorScheme.primary : color;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background container + icon ──────────────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Center(
              child: Icon(
                iconData,
                size: iconSize,
                color: displayColor.withValues(alpha: 0.85),
              ),
            ),
          ),

          // ── Color badge dot (bottom-right) ───────────────────────────────
          if (badgeSize > 0)
            Positioned(
              right: -badgeSize * 0.15,
              bottom: -badgeSize * 0.15,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
