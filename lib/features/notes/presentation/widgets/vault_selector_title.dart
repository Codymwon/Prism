import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../../../folders/data/folder_model.dart';
import '../../../../core/utils/utils.dart';
import 'vault_selector_bottom_sheet.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class VaultSelectorTitle extends ConsumerWidget {
  const VaultSelectorTitle({super.key});

  Future<void> _showVaultSelectorBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSpacing.borderRadiusLarge)),
      ),
      builder: (ctx) => const VaultSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeVaultName = ref.watch(activeVaultNameProvider).valueOrNull ?? 'My Vault';
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final foldersAsync = ref.watch(foldersProvider);

    VirtualFolder? activeFolder;
    if (selectedFolderId != null) {
      foldersAsync.whenData((list) {
        try {
          activeFolder = list.firstWhere((f) => f.id == selectedFolderId);
        } catch (_) {}
      });
    }

    final currentFolder = activeFolder;
    final folderColor = currentFolder?.colorHex.toColor() ?? const Color(0xFF7C6FF7);

    return TactileWrapper(
      onTap: () => _showVaultSelectorBottomSheet(context),
      style: TactileFeedbackStyle.standard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'PRISM',
            style: DesignTypography.display(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ).copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: DesignColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DesignColors.border(context),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentFolder != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: folderColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  Icon(DesignIcons.folderOpen, size: 12, color: DesignColors.textSecondary(context)),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    currentFolder != null ? '$activeVaultName / ${currentFolder.name}' : activeVaultName,
                    style: DesignTypography.heading(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  DesignIcons.arrowDown,
                  size: 14,
                  color: DesignColors.textSecondary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
