import 'package:flutter/material.dart';
import 'typography.dart';
import 'icons.dart';

class DesignSheetDragHandle extends StatelessWidget {
  const DesignSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class DesignSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const DesignSheetHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DesignSheetDragHandle(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: DesignTypography.heading(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(DesignIcons.close),
                onPressed: onClose,
              ),
          ],
        ),
      ],
    );
  }
}

class DesignDialogs {
  static void showSimpleConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(content, style: DesignTypography.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: DesignTypography.details(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              confirmText,
              style: DesignTypography.details(context, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
