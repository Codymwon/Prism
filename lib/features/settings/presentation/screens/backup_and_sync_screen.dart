import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/export_bottom_sheet.dart';
import '../../../../core/services/google_drive_service.dart';
import '../../../../core/services/two_way_sync_service.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../../core/services/vault_service.dart';

class BackupAndSyncScreen extends ConsumerStatefulWidget {
  const BackupAndSyncScreen({super.key});

  @override
  ConsumerState<BackupAndSyncScreen> createState() => _BackupAndSyncScreenState();
}

class _BackupAndSyncScreenState extends ConsumerState<BackupAndSyncScreen> {
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
      _errorMessage = 'Error initializing sync service: $e';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully.')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to sign out: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleConfigureSync() async {
    final pass = _passphraseController.text.trim();
    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Passphrase cannot be empty');
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync configured successfully!'),
              backgroundColor: Colors.green,
            ),
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
      // Show confirmation dialog: Keep or Delete
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DesignColors.surface(context),
          title: Text(
            'Disable Sync for $vaultName?',
            style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Would you like to keep your encrypted backup on Google Drive, or delete it from the cloud?',
            style: DesignTypography.body(context, fontSize: 14, color: DesignColors.textSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text('Cancel', style: TextStyle(color: DesignColors.textSecondary(context))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: Text('Keep in Cloud', style: TextStyle(color: DesignColors.primary(context))),
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
            setState(() => _errorMessage = 'Failed to delete cloud data: ${fail.message}');
          },
          (_) async {
            await syncedVaultsNotifier.disableSync(vaultName);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cloud backup for $vaultName deleted successfully.')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sync successful! Uploaded: ${result.uploaded}, Downloaded: ${result.downloaded}',
              ),
              backgroundColor: Colors.green,
            ),
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
        title: const Text('Purge All Cloud Backups?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete all synced vaults and files from your Google Drive AppData folder and sign you out.',
              style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your global sync passphrase to confirm:',
              style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Sync Passphrase',
                border: OutlineInputBorder(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect passphrase!'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Purge Everything'),
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
          // Clear passphrase
          await ref.read(secureStorageProvider).write(key: 'sync_passphrase', value: null);
          
          // Disable sync for all vaults
          final syncedVaults = ref.read(syncedVaultsProvider).valueOrNull ?? [];
          for (final vault in syncedVaults) {
            await ref.read(syncedVaultsProvider.notifier).disableSync(vault);
          }

          setState(() {
            _isSyncConfigured = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All cloud data purged and signed out successfully!'),
                backgroundColor: Colors.green,
              ),
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
          'Backup & Sync',
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // ── Premium Badge Header ──────────────────────────────────────────
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
                      'Global Selective Sync',
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
                        'Secure your notes with end-to-end encryption. Toggle sync for each vault individually and keep your data backed up on Google Drive.',
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
                  const SettingsSectionHeader(title: 'Google Drive Connection'),
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
                              'Connect your Google Drive account to enable cloud backups.',
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
                              label: const Text('Connect Google Drive'),
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
                                  tooltip: 'Disconnect Account',
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
                    const SettingsSectionHeader(title: 'Security & Encryption'),
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
                                          'End-to-End Encryption Active',
                                          style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'All notes are encrypted on-device before syncing.',
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
                                  labelText: 'Sync Passphrase',
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
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error loading vaults: $err', style: const TextStyle(color: Colors.red)),
                        data: (vaults) {
                          return syncedVaultsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
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
                                      activeColor: DesignColors.primary(context),
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

                  // ── Local Utilities ────────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Local Utilities'),
                  SettingsTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export vault',
                    subtitle: 'Download all notes as ZIP, PDF or JSON',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ExportBottomSheet(),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
                ],
              ),
      ),
    );
  }
}
