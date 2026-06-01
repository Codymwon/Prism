import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/data/note_model.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final repo = ref.read(noteRepositoryProvider);
    final suggestionsFuture = repo.getTitleSuggestions(query);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 60 + MediaQuery.of(context).viewInsets.bottom,
      child: Material(
        color: Colors.transparent,
        child: FutureBuilder<List<Note>>(
          future: suggestionsFuture,
          builder: (context, snapshot) {
            final notes = snapshot.data ?? [];
            final showCreate = notes.isEmpty ||
                !notes.any((n) => n.title.toLowerCase() == query.toLowerCase());

            final items = [
              ...notes,
            ];

            if (items.isEmpty && !showCreate) return const SizedBox.shrink();

            return Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
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
                        Icon(Icons.link_rounded, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Link to note',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
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
                              colorScheme,
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
                            colorScheme,
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
            ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.1);
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
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
                  ? colorScheme.primary
                  : (isGhost
                      ? (isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary)
                      : (isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isCreate
                          ? colorScheme.primary
                          : (isDark ? MeridianColors.darkText : MeridianColors.lightText),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
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
