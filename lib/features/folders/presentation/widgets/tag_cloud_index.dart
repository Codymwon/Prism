import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../providers/folders_providers.dart';
import 'package:prism/l10n/l10n.dart';

class TagCloudIndex extends ConsumerWidget {
  const TagCloudIndex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(uniqueTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            context.l10n.folders_tag_cloud_title,
            style: DesignTypography.metadata(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DesignColors.textTertiary(context),
            ).copyWith(letterSpacing: 1.0),
          ),
        ),
        tagsAsync.maybeWhen(
          data: (tags) => _buildTagWrap(context, ref, tags, selectedTag, colorScheme),
          orElse: () {
            if (tagsAsync.hasValue) {
              return _buildTagWrap(context, ref, tagsAsync.value!, selectedTag, colorScheme);
            }
            return const Padding(
              padding: EdgeInsets.all(10.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Loading'),
              ),
            );
          },
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              context.l10n.folders_tag_cloud_error(err.toString()),
              style: TextStyle(color: colorScheme.error, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagWrap(
    BuildContext context,
    WidgetRef ref,
    List<String> tags,
    String? selectedTag,
    ColorScheme colorScheme,
  ) {
    if (tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Text(
          context.l10n.folders_tag_cloud_empty,
          style: DesignTypography.details(
            context,
            fontSize: 11,
            color: DesignColors.textTertiary(context),
          ).copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.map((tag) {
          final isSelected = selectedTag == tag;
          return TactileWrapper(
            style: TactileFeedbackStyle.standard,
            onTap: () {
              // Set selected tag and clear folder filter
              ref.read(selectedTagProvider.notifier).state = isSelected ? null : tag;
              ref.read(selectedFolderIdProvider.notifier).state = null;
              
              // Close drawer
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : DesignColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : DesignColors.border(context),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.label_outline_rounded,
                    size: 11,
                    color: isSelected ? Colors.white : colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#$tag',
                    style: DesignTypography.body(
                      context,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : DesignColors.text(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}