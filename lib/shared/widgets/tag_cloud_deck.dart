import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/l10n/l10n.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/notes/presentation/providers/notes_providers.dart';
import '../design_system/design_system.dart';
import 'dynamic_island_state.dart';
import 'prism_toast.dart';
import 'tactile_wrapper.dart';

/// In-island subdeck displaying available tags and 1-tap tag filtering.
class TagCloudDeck extends ConsumerWidget {
  const TagCloudDeck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(uniqueTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Back button, Title, and Tag count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TactileWrapper(
                    key: const ValueKey('tag_cloud_back_btn'),
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(dynamicIslandControllerProvider.notifier)
                          .switchVaultHubSubDeck(VaultHubSubDeck.tools);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceVariant(context)
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: DesignColors.text(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TAGS',
                    style: DesignTypography.heading(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              tagsAsync.when(
                data: (tags) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context)
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DesignColors.border(context)
                          .withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${tags.length} ${tags.length == 1 ? 'Tag' : 'Tags'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DesignColors.textSecondary(context),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scrollable Tags Chip Cloud
          Flexible(
            child: tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 26,
                            color: DesignColors.textTertiary(context),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.folders_tag_cloud_empty,
                            style: DesignTypography.body(
                              context,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ).copyWith(
                              color: DesignColors.textSecondary(context),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) {
                        final isSelected = selectedTag == tag;

                        return TactileWrapper(
                          key: ValueKey('tag_chip_$tag'),
                          style: TactileFeedbackStyle.standard,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(selectedTagProvider.notifier).state =
                                isSelected ? null : tag;
                            ref.read(selectedFolderIdProvider.notifier).state =
                                null;
                            ref
                                .read(dynamicIslandControllerProvider.notifier)
                                .dismiss();
                            PrismToast.show(
                              context,
                              isSelected
                                  ? 'Tag filter cleared'
                                  : 'Filtered by #$tag',
                              icon: Icons.tag_rounded,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : DesignColors.surfaceVariant(context)
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : DesignColors.border(context)
                                        .withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  size: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : DesignColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading tags: $err',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
