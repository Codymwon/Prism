import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';

class GroupedEmptyState extends ConsumerWidget {
  const GroupedEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
            const SizedBox(height: 24),
            Text(
              'Organize your thoughts',
              style: DesignTypography.display(
                context,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
            const SizedBox(height: 12),
            Text(
              'Create virtual folders to categorize your notes by topic, project, or area of focus. All physical files remain safely on your device.',
              style: DesignTypography.body(
                context,
                fontSize: 14,
                color: DesignColors.textSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
            const SizedBox(height: 36),
            
            // Clean premium CTA button
            DesignPrimaryButton(
              label: 'Create First Folder',
              icon: DesignIcons.addFolder,
              onTap: () => FolderDrawer.showAddFolderSheet(context, ref),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
