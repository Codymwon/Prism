import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/database/vault_providers.dart';
import 'package:prism/l10n/l10n.dart';

class VaultStatusPanel extends ConsumerWidget {
  const VaultStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncNotifier — unwrap safely; show placeholder while loading
    final activeVaultName = ref.watch(activeVaultNameProvider).valueOrNull ?? 'Loading...';
    final activeVaultPath = ref.watch(activeVaultPathProvider).valueOrNull ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignColors.border(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(DesignIcons.folderOpen, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeVaultName.toUpperCase(),
                  style: DesignTypography.heading(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: DesignColors.text(context),
                  ).copyWith(letterSpacing: 1.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              // Status Dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeVaultPath.isEmpty ? context.l10n.folders_status_panel_loading_path : activeVaultPath,
            style: DesignTypography.mono(
              fontSize: 10,
              color: DesignColors.textTertiary(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.offline_pin_outlined, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  context.l10n.folders_status_panel_ready,
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}