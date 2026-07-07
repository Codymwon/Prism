import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/presentation/providers/notes_providers.dart';

class WikilinkAutocomplete extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;

  const WikilinkAutocomplete({
    super.key,
    required this.query,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestionsAsync = ref.watch(autocompleteSuggestionsProvider(query));

    return Positioned(
      left: 16,
      right: 16,
      bottom: 60 + MediaQuery.of(context).viewInsets.bottom,
      child: Material(
        color: Colors.transparent,
        child: suggestionsAsync.when(
          data: (notes) {
            final showCreate = notes.isEmpty ||
                !notes.any((n) => n.title.toLowerCase() == query.toLowerCase());

            final items = [
              ...notes,
            ];

            if (items.isEmpty && !showCreate) return const SizedBox.shrink();

            return Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: DesignColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignColors.border(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 13, color: DesignColors.primary(context)),
                        const SizedBox(width: 6),
                        Text(
                          'Link to note',
                          style: DesignTypography.heading(
                            context,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DesignColors.textSecondary(context),
                          ).copyWith(letterSpacing: 0.3),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: DesignColors.textTertiary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    color: DesignColors.border(context),
                  ),
                  // Suggestions list
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        ...items.map((note) => _buildSuggestionTile(
                              context,
                              isDark,
                              note.title,
                              subtitle: note.isGhost ? 'Ghost note' : '${note.wordCount} words',
                              icon: note.isGhost
                                  ? Icons.radio_button_unchecked_rounded
                                  : Icons.article_rounded,
                              isGhost: note.isGhost,
                            )),
                        // Create new option
                        if (showCreate)
                          _buildSuggestionTile(
                            context,
                            isDark,
                            query,
                            subtitle: 'Create new note',
                            icon: Icons.add_circle_outline_rounded,
                            isCreate: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            height: 60,
            decoration: BoxDecoration(
              color: DesignColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignColors.border(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Loading'),
              ),
            ),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    bool isDark,
    String title, {
    String? subtitle,
    required IconData icon,
    bool isGhost = false,
    bool isCreate = false,
  }) {
    return InkWell(
      onTap: () => onSelect(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isCreate
                  ? DesignColors.primary(context)
                  : (isGhost
                      ? DesignColors.textTertiary(context)
                      : DesignColors.textSecondary(context)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTypography.heading(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isCreate
                          ? DesignColors.primary(context)
                          : DesignColors.text(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 11,
                        color: DesignColors.textTertiary(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
