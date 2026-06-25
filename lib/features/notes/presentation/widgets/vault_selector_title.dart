import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
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
    final activeVaultName = ref.watch(activeVaultNameProvider).valueOrNull ?? 'My Vault';

    return TactileWrapper(
      onTap: () => _showVaultSelectorBottomSheet(context),
      style: TactileFeedbackStyle.standard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 140),
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
            Icon(DesignIcons.folderOpen, size: 12, color: DesignColors.textSecondary(context)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                activeVaultName,
                style: DesignTypography.heading(
                  context,
                  fontSize: 12,
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
    );
  }
}
