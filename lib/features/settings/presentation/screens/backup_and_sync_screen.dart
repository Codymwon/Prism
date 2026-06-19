import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/export_bottom_sheet.dart';
import '../../../../core/services/google_drive_service.dart';
import '../../../../core/services/two_way_sync_service.dart';

class BackupAndSyncScreen extends ConsumerWidget {
  const BackupAndSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: ListView(
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
                'Offline-First Security',
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
                  'Prism is designed from the ground up to respect your digital privacy. All notes reside solely on your device. You can opt to configure automated cloud sync or perform physical exports below.',
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

            // ── Cloud Services ────────────────────────────────────────────────
            const SettingsSectionHeader(title: 'Cloud Services')
                .animate()
                .fadeIn(delay: 250.ms, duration: 400.ms),
            ProGateTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Google Drive Sync',
              subtitle: 'Sync your vault to Google Drive',
              onTap: () => _showSyncSettingsBottomSheet(context, ref),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // ── Local Utilities ────────────────────────────────────────────────
            const SettingsSectionHeader(title: 'Local Utilities')
                .animate()
                .fadeIn(delay: 350.ms, duration: 400.ms),
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
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  void _showSyncSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _SyncBottomSheetContent();
      },
    );
  }
}

class _SyncBottomSheetContent extends ConsumerStatefulWidget {
  const _SyncBottomSheetContent();

  @override
  ConsumerState<_SyncBottomSheetContent> createState() => _SyncBottomSheetContentState();
}

class _SyncBottomSheetContentState extends ConsumerState<_SyncBottomSheetContent> {
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync configured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handleSyncNow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final res = await ref.read(twoWaySyncServiceProvider).runSync();
    res.fold(
      (fail) => setState(() => _errorMessage = fail.message),
      (result) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync successful! Uploaded: ${result.uploaded}, Downloaded: ${result.downloaded}, Resolved Conflicts: ${result.conflictsResolved}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handleDisableSync() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await ref.read(googleDriveServiceProvider).signOut();
      await ref.read(secureStorageProvider).write(key: 'sync_passphrase', value: null);
      _isSyncConfigured = false;
      _passphraseController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync disabled successfully.'),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Failed to disable sync: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final driveService = ref.watch(googleDriveServiceProvider);
    final isGoogleSignedIn = driveService.isSignedIn;

    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Google Drive Sync',
                style: DesignTypography.heading(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
            const SizedBox(height: 16),
          ],

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!isGoogleSignedIn) ...[
            // ── Google Sign In State ──────────────────────────────────────────
            Text(
              'Prism uses Google Drive to backup and sync your notes securely in a private app directory. Grant Prism access to proceed.',
              style: DesignTypography.body(
                context,
                fontSize: 13,
                color: DesignColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignColors.primary(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign In with Google'),
              onPressed: _handleGoogleSignIn,
            ),
          ] else if (_isSyncConfigured == false) ...[
            // ── Setup E2EE Passphrase State ──────────────────────────────────
            Text(
              'Set a Passphrase for End-to-End Encryption (E2EE)',
              style: DesignTypography.body(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prism encrypts your files on-device before uploading to Google Drive. Prism does not store your passphrase. If lost, you cannot recover your notes on new devices.',
              style: DesignTypography.body(
                context,
                fontSize: 12,
                color: DesignColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passphraseController,
              obscureText: _obscurePassphrase,
              decoration: InputDecoration(
                labelText: 'Passphrase',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassphrase ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  ),
                  onPressed: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignColors.primary(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _handleConfigureSync,
              child: const Text('Enable Sync'),
            ),
          ] else ...[
            // ── Sync Active State ─────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End-to-End Encrypted Sync Active',
                        style: DesignTypography.body(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Your data is encrypted and synced with Google Drive.',
                        style: DesignTypography.body(
                          context,
                          fontSize: 12,
                          color: DesignColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignColors.primary(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync Now'),
              onPressed: _handleSyncNow,
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: _handleDisableSync,
              child: const Text('Disable Sync & Sign Out'),
            ),
          ],
        ],
      ),
    );
  }
}
