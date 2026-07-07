import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/l10n/l10n.dart';
import '../../../../shared/design_system/design_system.dart';
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

    final backlinks = backlinksAsync.valueOrNull;
    if (backlinks == null || backlinks.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildPanel(context, isDark, colorScheme, backlinks);
  }

  Widget _buildPanel(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    List<Backlink> backlinks,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        border: Border(
          top: BorderSide(
            color: DesignColors.border(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
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
                      color: DesignColors.primary(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.editor_backlinks_panel_title(backlinks.length),
                      style: DesignTypography.heading(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignColors.primary(context),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_less_rounded,
                        size: 18,
                        color: DesignColors.textSecondary(context),
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
                  color: DesignColors.border(context),
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
                Icon(Icons.article_outlined, size: 13, color: DesignColors.primary(context)),
                const SizedBox(width: 6),
                Text(
                  backlink.sourceTitle,
                  style: DesignTypography.heading(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DesignColors.primary(context),
                  ),
                ),
              ],
            ),
            if (backlink.contextSnippet != null) ...[
              const SizedBox(height: 4),
              Text(
                backlink.contextSnippet!,
                style: DesignTypography.body(
                  context,
                  fontSize: 12,
                  height: 1.5,
                  color: DesignColors.textSecondary(context),
                ).copyWith(fontStyle: FontStyle.italic),
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
