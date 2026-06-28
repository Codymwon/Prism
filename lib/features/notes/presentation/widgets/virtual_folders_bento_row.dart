import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../data/note_model.dart';

class VirtualFoldersBentoRow extends ConsumerWidget {
  final List<Note> allNotes;
  final List<VirtualFolder> folders;
  final Map<String, List<String>> mappings;
  final bool showAll;

  const VirtualFoldersBentoRow({
    super.key,
    required this.allNotes,
    required this.folders,
    required this.mappings,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFolderId = ref.watch(selectedFolderIdProvider);

    // 1. Calculate dynamic counts
    final allNotesCount = allNotes.where((n) => !n.isDaily && !n.isGhost).length;
    final dailyNotesCount = allNotes.where((n) => n.isDaily && !n.isGhost).length;
    final uncategorizedCount = allNotes
        .where((n) => !n.isDaily && !n.isGhost && (mappings[n.id] == null || mappings[n.id]!.isEmpty))
        .length;

    final systemCardColor = DesignColors.surfaceVariant(context);

    // 2. Prepare Bento Cards definitions
    final List<_BentoCardData> cards = [
      // Card 0: All Notes
      _BentoCardData(
        id: '__all__',
        name: 'All Notes',
        icon: 'article',
        color: systemCardColor,
        count: allNotesCount,
        isSystem: true,
      ),
      // Card 1: Journal Logs (Daily Notes)
      _BentoCardData(
        id: '__daily__',
        name: 'Journal Logs',
        icon: 'auto_stories',
        color: systemCardColor,
        count: dailyNotesCount,
        isSystem: true,
      ),
      // Card 3: Uncategorized Notes
      _BentoCardData(
        id: '__uncategorized__',
        name: 'Uncategorized',
        icon: 'inbox',
        color: systemCardColor,
        count: uncategorizedCount,
        isSystem: true,
      ),
      // User virtual folders
      ...folders.map(
        (f) => _BentoCardData(
          id: f.id,
          name: f.name,
          icon: f.icon,
          color: f.colorHex.toColor(),
          count: f.noteCount,
          isSystem: false,
          folder: f,
        ),
      ),
    ];

    // 3. Grid Slicing & See All Injection (only when showAll is false)
    List<_BentoCardData> displayCards = cards;
    if (!showAll && cards.length > 6) {
      displayCards = cards.take(5).toList();
      displayCards.add(
        _BentoCardData(
          id: '__folders__',
          name: 'See All',
          icon: 'more_horiz',
          color: systemCardColor,
          count: cards.length - 5,
          isSystem: true,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      padding: showAll 
          ? const EdgeInsets.symmetric(vertical: 12)
          : const EdgeInsets.fromLTRB(16, 0, 16, 4),
      physics: showAll 
          ? const ScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: showAll ? 2 : 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: showAll ? 1.45 : 1.2,
      ),
      itemCount: displayCards.length,
      itemBuilder: (context, index) {
        final card = displayCards[index];
        final isSelected = selectedFolderId == card.id;

        final cardBg = card.color;
        final isLightBg = cardBg.computeLuminance() > 0.5;
        final textColor = isLightBg ? const Color(0xFF2D2A26) : Colors.white;
        final badgeBg = isLightBg ? Colors.black.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.25);

        return TactileWrapper(
          style: TactileFeedbackStyle.standard,
          onTap: () {
            ref.read(selectedFolderIdProvider.notifier).state = card.id;
          },
          onLongPress: card.folder != null
              ? () => FolderDrawer.showFolderOptions(context, ref, card.folder!)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? textColor : Colors.black.withValues(alpha: 0.08),
                width: isSelected ? 2.5 : 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (card.icon.isNotEmpty)
                      Icon(
                        DesignIcons.resolveFolder(card.icon),
                        size: 16,
                        color: textColor.withValues(alpha: 0.8),
                      )
                    else
                      const SizedBox.shrink(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${card.count}',
                        style: DesignTypography.mono(
                          fontSize: 8.5,
                          color: textColor,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Text(
                  card.name,
                  style: DesignTypography.body(
                    context,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BentoCardData {
  final String? id;
  final String name;
  final String icon;
  final Color color;
  final int count;
  final bool isSystem;
  final VirtualFolder? folder;

  const _BentoCardData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    this.isSystem = false,
    this.folder,
  });
}
