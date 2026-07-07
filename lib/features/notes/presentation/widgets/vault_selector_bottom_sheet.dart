import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/services/vault_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../folders/presentation/providers/folders_providers.dart';

class VaultSelectorBottomSheet extends ConsumerStatefulWidget {
  const VaultSelectorBottomSheet({super.key});

  @override
  ConsumerState<VaultSelectorBottomSheet> createState() => _VaultSelectorBottomSheetState();
}

class _VaultSelectorBottomSheetState extends ConsumerState<VaultSelectorBottomSheet> {
  Future<void> _switchVault(String vaultName) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Dismiss bottom sheet immediately

    try {
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref.read(vaultManagementServiceProvider).switchVault(vaultName: vaultName);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error switching vault: $e', style: const TextStyle(color: Colors.white))),
      );
    }
  }

  void _showCreateVaultDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return _CreateVaultDialog(
          onConfirm: (name) => _createNewVault(name),
        );
      },
    );
  }

  Future<void> _createNewVault(String vaultName) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Dismiss bottom sheet immediately

    try {
      // Await async provider to get the real loaded value
      final baseDir = await ref.read(baseVaultsDirectoryProvider.future);
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref.read(vaultManagementServiceProvider).createVault(
        vaultName: vaultName,
        baseDir: baseDir,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error creating vault: $e', style: const TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // AsyncNotifier — unwrap safely
    final activeVault = ref.watch(activeVaultNameProvider).valueOrNull ?? '';
    
    // Watch the availableVaultsProvider directly. Since it is already warmed up
    // during app startup, it will instantly have data when the user opens the bottom sheet!
    final vaultsAsync = ref.watch(availableVaultsProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const DesignSheetDragHandle(),
          const SizedBox(height: 8),
          Text(
            'Switch Vault',
            style: DesignTypography.heading(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: vaultsAsync.when(
              data: (vaults) {
                if (vaults.isEmpty) {
                  return const Center(child: Text('No vaults found'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: vaults.length,
                  itemBuilder: (c, idx) {
                    final vaultName = vaults[idx];
                    final isActive = vaultName == activeVault;

                    return ListTile(
                      leading: Icon(
                        DesignIcons.folder,
                        color: isActive ? colorScheme.primary : DesignColors.textSecondary(context),
                      ),
                      title: Text(
                        vaultName,
                        style: DesignTypography.body(
                          context,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isActive ? Icon(DesignIcons.check, color: colorScheme.primary) : null,
                      onTap: () async {
                        if (!isActive) {
                          await _switchVault(vaultName);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(semanticsLabel: 'Loading'),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error loading vaults: $err'),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(DesignIcons.add, color: colorScheme.primary),
            title: Text(
              'Create New Vault',
              style: DesignTypography.heading(
                context,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            onTap: () {
              _showCreateVaultDialog();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CreateVaultDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;

  const _CreateVaultDialog({required this.onConfirm});

  @override
  State<_CreateVaultDialog> createState() => _CreateVaultDialogState();
}

class _CreateVaultDialogState extends State<_CreateVaultDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignColors.surface(context),
      title: Text(
        'Create New Vault',
        style: DesignTypography.heading(context, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: DesignTypography.body(context),
        decoration: InputDecoration(
          hintText: 'Vault Name',
          hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
          filled: true,
          fillColor: DesignColors.surfaceVariant(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
            borderSide: BorderSide(color: DesignColors.border(context)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: DesignTypography.details(context)),
        ),
        TextButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
            if (!safePattern.hasMatch(name)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vault name can only contain letters, numbers, spaces, underscores, and hyphens.')),
              );
              return;
            }
            Navigator.pop(context);
            widget.onConfirm(name);
          },
          child: Text('Create', style: DesignTypography.details(context, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
