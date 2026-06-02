import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../providers/notes_providers.dart';
import '../../data/note_model.dart';

class NotesSortButton extends ConsumerWidget {
  const NotesSortButton({super.key});

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSpacing.borderRadiusLarge)),
      ),
      builder: (ctx) => const NotesSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () => _showSortBottomSheet(context),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(
            color: DesignColors.border(context),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.swap_vert_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class NotesSortBottomSheet extends ConsumerWidget {
  const NotesSortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeSort = ref.watch(noteSortProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const DesignSheetDragHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Sort Order',
              style: DesignTypography.heading(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          _buildSortOptionTile(
            context: context,
            ref: ref,
            title: 'Last Updated (Recent)',
            description: 'Recently edited notes and folders float to the top',
            icon: Icons.access_time_rounded,
            value: NoteSort.updated,
            isActive: activeSort == NoteSort.updated,
            colorScheme: colorScheme,
          ),
          _buildSortOptionTile(
            context: context,
            ref: ref,
            title: 'Date Created',
            description: 'Newest folders and notes listed first',
            icon: Icons.calendar_today_rounded,
            value: NoteSort.created,
            isActive: activeSort == NoteSort.created,
            colorScheme: colorScheme,
          ),
          _buildSortOptionTile(
            context: context,
            ref: ref,
            title: 'Alphabetical (A–Z)',
            description: 'Sort notes and folders by name alphabetically',
            icon: Icons.sort_by_alpha_rounded,
            value: NoteSort.title,
            isActive: activeSort == NoteSort.title,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSortOptionTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String description,
    required IconData icon,
    required NoteSort value,
    required bool isActive,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TactileWrapper(
        style: TactileFeedbackStyle.standard,
        onTap: () {
          ref.read(noteSortProvider.notifier).state = value;
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : DesignColors.surfaceVariant(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? colorScheme.primary : DesignColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: DesignTypography.body(
                        context,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? colorScheme.primary : DesignColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: DesignTypography.details(
                        context,
                        fontSize: 11,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
