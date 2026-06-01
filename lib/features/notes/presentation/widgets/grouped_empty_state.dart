import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../data/note_repository.dart';

class GroupedEmptyState extends ConsumerWidget {
  const GroupedEmptyState({super.key});

  Future<void> _createQuickNote(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.createNote();
    if (context.mounted) {
      context.push('/editor/${note.id}?new=true');
    }
  }

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
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Organize your thoughts',
              style: DesignTypography.display(
                context,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
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
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
            const SizedBox(height: 36),
            
            // Clean premium CTA buttons
            Column(
              children: [
                DesignPrimaryButton(
                  label: 'Create First Folder',
                  icon: DesignIcons.addFolder,
                  onTap: () => FolderDrawer.showAddFolderSheet(context, ref),
                ),
                const SizedBox(height: 12),
                DesignSecondaryButton(
                  label: 'Create Quick Note',
                  icon: Icons.note_add_outlined,
                  onTap: () => _createQuickNote(context, ref),
                ),
              ],
            ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }
}
