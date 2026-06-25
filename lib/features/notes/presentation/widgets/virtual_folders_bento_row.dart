import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../../folders/data/folder_model.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/presentation/widgets/folder_drawer.dart';
import '../../../folders/presentation/widgets/folder_icon_display.dart';
import '../../data/note_model.dart';

class VirtualFoldersBentoRow extends ConsumerWidget {
  final List<Note> allNotes;
  final List<VirtualFolder> folders;
  final Map<String, List<String>> mappings;

  const VirtualFoldersBentoRow({
    super.key,
    required this.allNotes,
    required this.folders,
    required this.mappings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Calculate dynamic counts
    final allNotesCount = allNotes.where((n) => !n.isDaily && !n.isGhost).length;
    final dailyNotesCount = allNotes.where((n) => n.isDaily && !n.isGhost).length;
    final uncategorizedCount = allNotes
        .where((n) => !n.isDaily && !n.isGhost && (mappings[n.id] == null || mappings[n.id]!.isEmpty))
        .length;

    // 2. Prepare Bento Cards definitions
    final List<_BentoCardData> cards = [
      // Card 0: All Notes
      _BentoCardData(
        id: null,
        name: 'All Notes',
        icon: 'article',
        color: colorScheme.primary,
        count: allNotesCount,
        isSystem: true,
      ),
      // Card 1: Add Button (+)
      _BentoCardData(
        id: '__add__',
        name: 'New Folder',
        icon: 'add_folder',
        color: colorScheme.primary,
        count: 0,
        isSystem: true,
        isAdd: true,
      ),
      // Card 2: Daily Notes
      _BentoCardData(
        id: '__daily__',
        name: 'Daily Notes',
        icon: 'auto_stories',
        color: Colors.amber,
        count: dailyNotesCount,
        isSystem: true,
      ),
      // Card 3: Uncategorized Notes
      _BentoCardData(
        id: '__uncategorized__',
        name: 'Uncategorized',
        icon: 'inbox',
        color: Colors.blueGrey,
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

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final isSelected = selectedFolderId == card.id;

        if (card.isAdd) {
          // Render Outlined Add Folder Button
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TactileWrapper(
              style: TactileFeedbackStyle.highImpact,
              onTap: () => FolderDrawer.showAddFolderSheet(context, ref),
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.primary.withValues(alpha: 0.05) : colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.create_new_folder_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create Folder',
                      style: DesignTypography.body(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Render Standard Folder Bento Card
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TactileWrapper(
            style: TactileFeedbackStyle.standard,
            onTap: () {
              ref.read(selectedFolderIdProvider.notifier).state = card.id;
            },
            onLongPress: card.folder != null
                ? () => FolderDrawer.showFolderOptions(context, ref, card.folder!)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? card.color.withValues(alpha: 0.12)
                    : DesignColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? card.color
                      : DesignColors.border(context),
                  width: isSelected ? 1.5 : 0.8,
                ),
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
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
                      FolderIconDisplay(
                        iconKey: card.icon,
                        color: card.color,
                        size: 32,
                        badgeSize: card.isSystem ? 0 : 8,
                        useThemedIcon: true,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? card.color.withValues(alpha: 0.25)
                              : card.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${card.count}',
                          style: DesignTypography.mono(
                            fontSize: 10,
                            color: card.color,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    card.name,
                    style: DesignTypography.body(
                      context,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: DesignColors.text(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
  final bool isAdd;
  final VirtualFolder? folder;

  const _BentoCardData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    this.isSystem = false,
    this.isAdd = false,
    this.folder,
  });
}
