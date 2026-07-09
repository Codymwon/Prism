import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../widgets/settings_widgets.dart';
import '../../../../shared/widgets/prism_toast.dart';
import '../../../../core/services/google_drive_service.dart';
import '../../../../core/services/two_way_sync_service.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../../core/services/vault_service.dart';
import 'package:prism/l10n/l10n.dart';

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassphrase = true;
  bool? _isSyncConfigured;
  final _passphraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    final driveService = ref.read(googleDriveServiceProvider);
    setState(() => _isLoading = true);
    try {
      if (!driveService.isSignedIn) {
        await driveService.signInSilently();
      }
      if (driveService.isSignedIn) {
        _isSyncConfigured = await ref.read(twoWaySyncServiceProvider).isSyncConfigured();
      }
    } catch (e) {
      _errorMessage = context.l10n.settings_cloud_sync_init_error(e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final res = await ref.read(googleDriveServiceProvider).signIn();
    await res.fold(
      (fail) async => setState(() => _errorMessage = fail.message),
      (_) async {
        _isSyncConfigured = await ref.read(twoWaySyncServiceProvider).isSyncConfigured();
      },
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await ref.read(googleDriveServiceProvider).signOut();
      _isSyncConfigured = false;
      _passphraseController.clear();
      if (mounted) {
        PrismToast.show(
          context,
          context.l10n.settings_cloud_sync_signout_success,
          icon: Icons.logout_rounded,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = context.l10n.settings_cloud_sync_signout_error(e.toString()));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleConfigureSync() async {
    final pass = _passphraseController.text.trim();
    if (pass.isEmpty) {
      setState(() => _errorMessage = context.l10n.settings_cloud_sync_passphrase_empty);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final res = await ref.read(twoWaySyncServiceProvider).configureSync(passphrase: pass);
    res.fold(
      (fail) => setState(() => _errorMessage = fail.message),
      (_) {
        setState(() {
          _isSyncConfigured = true;
        });
        if (mounted) {
          PrismToast.show(
            context,
            context.l10n.settings_cloud_sync_configured_success,
            icon: Icons.cloud_done_outlined,
          );
        }
      },
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handleToggleSync(String vaultName, bool enable) async {
    final syncedVaultsNotifier = ref.read(syncedVaultsProvider.notifier);
    final activeVault = ref.read(activeVaultNameProvider).valueOrNull ?? '';

    if (enable) {
      setState(() => _isLoading = true);
      await syncedVaultsNotifier.enableSync(vaultName);
      setState(() => _isLoading = false);

      if (vaultName == activeVault) {
        _triggerActiveVaultSync();
      }
    } else {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DesignColors.surface(context),
          title: Text(
            context.l10n.settings_cloud_sync_disable_title(vaultName),
            style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Text(
            context.l10n.settings_cloud_sync_disable_desc,
            style: DesignTypography.body(context, fontSize: 14, color: DesignColors.textSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text('Cancel', style: TextStyle(color: DesignColors.textSecondary(context))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: Text(context.l10n.settings_cloud_sync_keep_cloud_button, style: TextStyle(color: DesignColors.primary(context))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text('Delete from Cloud', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (choice == 'keep') {
        setState(() => _isLoading = true);
        await syncedVaultsNotifier.disableSync(vaultName);
        setState(() => _isLoading = false);
      } else if (choice == 'delete') {
        setState(() => _isLoading = true);
        final deleteRes = await ref.read(twoWaySyncServiceProvider).deleteVaultCloudData(vaultName);
        await deleteRes.fold(
          (fail) async {
            setState(() => _errorMessage = context.l10n.settings_cloud_sync_delete_cloud_error(fail.message));
          },
          (_) async {
            await syncedVaultsNotifier.disableSync(vaultName);
            if (mounted) {
              PrismToast.show(
                context,
                context.l10n.settings_cloud_sync_delete_cloud_success(vaultName),
                icon: Icons.delete_outline_rounded,
              );
            }
          },
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _triggerActiveVaultSync() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final res = await ref.read(twoWaySyncServiceProvider).runSync();
    res.fold(
      (fail) => setState(() => _errorMessage = fail.message),
      (result) {
        if (mounted) {
          PrismToast.show(
            context,
            context.l10n.settings_cloud_sync_sync_success(result.uploaded, result.downloaded),
            icon: Icons.sync_rounded,
          );
        }
      },
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handlePurgeCloudData() async {
    final storedPassphrase = await ref.read(secureStorageProvider).read(key: 'sync_passphrase');
    if (storedPassphrase == null) return;

    if (!mounted) return;
    final confirmController = TextEditingController();
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.surface(context),
        title: Text(context.l10n.settings_cloud_sync_purge_title, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.settings_cloud_sync_purge_desc,
              style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.settings_cloud_sync_purge_passphrase_prompt,
              style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.l10n.settings_cloud_sync_passphrase_label,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: DesignColors.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              if (confirmController.text == storedPassphrase) {
                Navigator.of(context).pop(true);
              } else {
                PrismToast.show(
                  context,
                  context.l10n.settings_cloud_sync_passphrase_incorrect,
                  icon: Icons.warning_amber_rounded,
                );
              }
            },
            child: Text(context.l10n.settings_cloud_sync_purge_everything_button),
          ),
        ],
      ),
    );

    confirmController.dispose();

    if (isConfirmed == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final purgeRes = await ref.read(googleDriveServiceProvider).purgeAppDataFolder();
      await purgeRes.fold(
        (fail) async => setState(() => _errorMessage = fail.message),
        (_) async {
          await ref.read(secureStorageProvider).delete(key: 'sync_passphrase');
          
          final syncedVaults = ref.read(syncedVaultsProvider).valueOrNull ?? [];
          for (final vault in syncedVaults) {
            await ref.read(syncedVaultsProvider.notifier).disableSync(vault);
          }

          setState(() {
            _isSyncConfigured = false;
          });

          if (mounted) {
            PrismToast.show(
              context,
              context.l10n.settings_cloud_sync_purge_success_msg,
              icon: Icons.cloud_off_rounded,
            );
          }
        },
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driveService = ref.watch(googleDriveServiceProvider);
    final isGoogleSignedIn = driveService.isSignedIn;
    final userEmail = driveService.currentUser?.email;
    final availableVaultsAsync = ref.watch(availableVaultsProvider);
    final syncedVaultsAsync = ref.watch(syncedVaultsProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: DesignColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(DesignIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.settings_cloud_sync_title,
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignColors.primary(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        size: 40,
                        color: DesignColors.primary(context),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      context.l10n.settings_cloud_sync_section_header,
                      style: DesignTypography.heading(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DesignColors.text(context),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        context.l10n.settings_cloud_sync_section_desc,
                        style: DesignTypography.body(
                          context,
                          fontSize: 13,
                          color: DesignColors.textSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 32),

                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Google Drive Connection ───────────────────────────────────────
                  SettingsSectionHeader(title: context.l10n.settings_cloud_sync_gdrive_header),
                  Card(
                    color: DesignColors.surface(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: DesignColors.text(context).withValues(alpha: 0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isGoogleSignedIn) ...[
                            Text(
                              context.l10n.settings_cloud_sync_gdrive_desc,
                              style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignColors.primary(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.login_rounded),
                              label: Text(context.l10n.settings_cloud_sync_connect_button),
                              onPressed: _handleGoogleSignIn,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(Icons.account_circle_rounded, size: 40, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Connected',
                                        style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      if (userEmail != null)
                                        Text(
                                          userEmail,
                                          style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                  onPressed: _handleGoogleSignOut,
                                  tooltip: context.l10n.settings_cloud_sync_disconnect_tooltip,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (isGoogleSignedIn) ...[
                    // ── Encryption Passphrase ─────────────────────────────────────────
                    SettingsSectionHeader(title: context.l10n.settings_cloud_sync_security_header),
                    Card(
                      color: DesignColors.surface(context),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: DesignColors.text(context).withValues(alpha: 0.05)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isSyncConfigured == true) ...[
                              Row(
                                children: [
                                  const Icon(Icons.shield_rounded, color: Colors.green, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.l10n.settings_cloud_sync_e2e_title,
                                          style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          context.l10n.settings_cloud_sync_e2e_desc,
                                          style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text(
                                'Set a Global Passphrase to Enable Encryption',
                                style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Prism encrypts your files on-device. Prism never stores your passphrase. If lost, you cannot recover your notes on new devices.',
                                style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passphraseController,
                                obscureText: _obscurePassphrase,
                                decoration: InputDecoration(
                                  labelText: context.l10n.settings_cloud_sync_passphrase_label,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassphrase ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    ),
                                    onPressed: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignColors.primary(context),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _handleConfigureSync,
                                child: const Text('Enable Sync & Encryption'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_isSyncConfigured == true) ...[
                      // ── Synced Vaults List ──────────────────────────────────────────
                      const SettingsSectionHeader(title: 'Vault Sync Settings'),
                      availableVaultsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading')),
                        error: (err, _) => Text('Error loading vaults: $err', style: const TextStyle(color: Colors.red)),
                        data: (vaults) {
                          return syncedVaultsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading')),
                            error: (err, _) => Text('Error loading sync config: $err', style: const TextStyle(color: Colors.red)),
                            data: (syncedVaults) {
                              return Column(
                                children: vaults.map((vault) {
                                  final isSynced = syncedVaults.contains(vault);
                                  return Card(
                                    color: DesignColors.surface(context),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(color: DesignColors.text(context).withValues(alpha: 0.05)),
                                    ),
                                    child: SwitchListTile(
                                      activeThumbColor: DesignColors.primary(context),
                                      title: Text(
                                        vault,
                                        style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        isSynced ? 'Syncing to Drive' : 'Local only',
                                        style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                                      ),
                                      value: isSynced,
                                      onChanged: (val) => _handleToggleSync(vault, val),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Danger Zone ─────────────────────────────────────────────────
                      const SettingsSectionHeader(title: 'Danger Zone'),
                      Card(
                        color: Colors.red.withValues(alpha: 0.05),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Purge Cloud Data',
                                style: DesignTypography.heading(context, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Deletes all encrypted vault backups and configurations from Google Drive. Your local vaults will remain untouched.',
                                style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _handlePurgeCloudData,
                                child: const Text('Purge Cloud Backups & Disconnect'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}