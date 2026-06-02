import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/data/note_model.dart';

class BacklinksPanel extends ConsumerStatefulWidget {
  final String noteId;

  const BacklinksPanel({super.key, required this.noteId});

  @override
  ConsumerState<BacklinksPanel> createState() => _BacklinksPanelState();
}

class _BacklinksPanelState extends ConsumerState<BacklinksPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final backlinksAsync = ref.watch(backlinksProvider(widget.noteId));

    return backlinksAsync.when(
      data: (backlinks) {
        if (backlinks.isEmpty) return const SizedBox.shrink();
        return _buildPanel(context, isDark, colorScheme, backlinks);
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    List<Backlink> backlinks,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 15,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${backlinks.length} backlink${backlinks.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_less_rounded,
                      size: 18,
                      color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Backlinks list
          AnimatedCrossFade(
            firstChild: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: backlinks.length,
              separatorBuilder: (ctx, idx) => Divider(
                height: 0.5,
                indent: 20,
                color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
              ),
              itemBuilder: (context, i) {
                final bl = backlinks[i];
                return _BacklinkTile(backlink: bl, isDark: isDark, colorScheme: colorScheme);
              },
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _BacklinkTile extends StatelessWidget {
  final Backlink backlink;
  final bool isDark;
  final ColorScheme colorScheme;

  const _BacklinkTile({
    required this.backlink,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/editor/${backlink.sourceId}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined, size: 13, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  backlink.sourceTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (backlink.contextSnippet != null) ...[
              const SizedBox(height: 4),
              Text(
                backlink.contextSnippet!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
