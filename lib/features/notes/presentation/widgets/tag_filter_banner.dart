import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../providers/notes_providers.dart';

class TagFilterBanner extends ConsumerWidget {
  const TagFilterBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTag = ref.watch(selectedTagProvider);
    if (selectedTag == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignSpacing.screenPadding, 0, DesignSpacing.screenPadding, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.label_outline_rounded, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Filtered by tag: #$selectedTag',
              style: DesignTypography.heading(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.read(selectedTagProvider.notifier).state = null,
              child: Icon(Icons.close_rounded, size: 16, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
