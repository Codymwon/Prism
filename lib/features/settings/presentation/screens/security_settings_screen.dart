import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/prism_toast.dart';
import '../widgets/settings_widgets.dart';
import '../../../../core/services/two_way_sync_service.dart';
import '../../../../core/config/app_config.dart';
import 'package:prism/l10n/l10n.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _isLoading = false;
  bool _isPassphraseConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final storage = ref.read(secureStorageProvider);
      final pass = await storage.read(key: 'sync_passphrase');
      if (mounted) {
        setState(() {
          _isPassphraseConfigured = pass != null && pass.isNotEmpty;
        });
      }
    } catch (_) {
      // Ignore secure storage read failures in mock environments
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSetOrChangePassphraseDialog() async {
    final currentStored = await ref.read(secureStorageProvider).read(key: 'sync_passphrase');
    final isChanging = currentStored != null && currentStored.isNotEmpty;

    if (!mounted) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => _SetOrChangePassphraseDialog(
        isChanging: isChanging,
        currentStored: currentStored,
        onSave: (newPass) async {
          await ref.read(secureStorageProvider).write(
                key: 'sync_passphrase',
                value: newPass,
              );
        },
      ),
    );

    if (updated == true && mounted) {
      await _loadStatus();
      if (mounted) {
        PrismToast.show(
          context,
          isChanging
              ? context.l10n.settings_security_passphrase_change_success
              : context.l10n.settings_security_passphrase_set_success,
          icon: Icons.check_circle_outline_rounded,
        );
      }
    }
  }

  Future<void> _showVerifyPassphraseDialog() async {
    final currentStored = await ref.read(secureStorageProvider).read(key: 'sync_passphrase');
    if (!mounted) return;

    final isCorrect = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => _VerifyPassphraseDialog(currentStored: currentStored),
    );

    if (isCorrect != null && mounted) {
      if (isCorrect) {
        PrismToast.show(
          context,
          context.l10n.settings_security_passphrase_verify_success,
          icon: Icons.verified_user_rounded,
        );
      } else {
        PrismToast.show(
          context,
          context.l10n.settings_security_passphrase_verify_failure,
          icon: Icons.warning_amber_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primaryColor = DesignColors.primary(context);

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
          l10n.settings_security_title,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  // ── Hero Header ──────────────────────────────────────────
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n.settings_security_title,
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
                        l10n.settings_security_desc,
                        style: DesignTypography.body(
                          context,
                          fontSize: 13,
                          color: DesignColors.textSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 28),

                  // ── 1. On-Device Encryption Status ───────────────────────
                  SettingsSectionHeader(title: l10n.settings_security_local_encryption),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.lock_rounded, color: Colors.green, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.settings_security_local_database_title,
                                      style: DesignTypography.body(
                                        context,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.settings_security_local_status_active,
                                        style: DesignTypography.metadata(
                                          context,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.settings_security_local_status_desc,
                            style: DesignTypography.details(context, color: DesignColors.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (AppConfig.enableSubscriptions) ...[
                    const SizedBox(height: 24),

                    // ── 2. Master Passphrase Management ──────────────────────
                    SettingsSectionHeader(title: l10n.settings_security_master_passphrase),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _isPassphraseConfigured
                                        ? primaryColor.withValues(alpha: 0.12)
                                        : Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isPassphraseConfigured ? Icons.key_rounded : Icons.lock_outline_rounded,
                                    color: _isPassphraseConfigured ? primaryColor : Colors.amber,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isPassphraseConfigured
                                            ? l10n.settings_security_passphrase_configured
                                            : l10n.settings_security_passphrase_not_configured,
                                        style: DesignTypography.body(
                                          context,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _isPassphraseConfigured
                                            ? 'Zero-knowledge cryptographic root active'
                                            : 'Passphrase not yet established',
                                        style: DesignTypography.details(context, color: DesignColors.textSecondary(context)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: Icon(
                                      _isPassphraseConfigured ? Icons.edit_rounded : Icons.add_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _isPassphraseConfigured
                                          ? l10n.settings_security_passphrase_change
                                          : l10n.settings_security_passphrase_set,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: _showSetOrChangePassphraseDialog,
                                  ),
                                ),
                                if (_isPassphraseConfigured) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      icon: const Icon(Icons.fact_check_outlined, size: 16),
                                      label: Text(
                                        l10n.settings_security_passphrase_verify,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: _showVerifyPassphraseDialog,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PBKDF2 Cryptographic Standards Explainer Card
                    Card(
                      color: DesignColors.surfaceVariant(context),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: DesignColors.border(context)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 16, color: primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.settings_security_pbkdf2_title,
                                  style: DesignTypography.body(
                                    context,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.settings_security_pbkdf2_subtitle,
                              style: DesignTypography.metadata(
                                context,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.settings_security_pbkdf2_desc,
                              style: DesignTypography.details(context, color: DesignColors.textSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. Cloud Sync Linkage ────────────────────────────────
                    SettingsSectionHeader(title: l10n.settings_cloud_sync_title),
                    SettingsTile(
                      icon: Icons.cloud_sync_rounded,
                      title: l10n.settings_security_cloud_sync_title,
                      subtitle: l10n.settings_security_cloud_sync_desc,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await context.push('/settings/cloud-sync');
                        _loadStatus();
                      },
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SetOrChangePassphraseDialog extends StatefulWidget {
  final bool isChanging;
  final String? currentStored;
  final Future<void> Function(String newPass) onSave;

  const _SetOrChangePassphraseDialog({
    required this.isChanging,
    required this.currentStored,
    required this.onSave,
  });

  @override
  State<_SetOrChangePassphraseDialog> createState() => _SetOrChangePassphraseDialogState();
}

class _SetOrChangePassphraseDialogState extends State<_SetOrChangePassphraseDialog> {
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = context.l10n;
    final newPass = _newController.text.trim();
    final confirmPass = _confirmController.text.trim();

    if (widget.isChanging) {
      final currPass = _currentController.text.trim();
      if (currPass != widget.currentStored) {
        setState(() => _error = l10n.settings_cloud_sync_passphrase_incorrect);
        return;
      }
    }

    if (newPass.isEmpty) {
      setState(() => _error = l10n.settings_cloud_sync_passphrase_empty);
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _error = l10n.settings_security_passphrase_mismatch);
      return;
    }

    await widget.onSave(newPass);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: DesignColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.password_rounded, color: DesignColors.primary(context), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isChanging
                  ? l10n.settings_security_change_passphrase_dialog_title
                  : l10n.settings_security_set_passphrase_dialog_title,
              style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: DesignTypography.details(context, color: Colors.red),
                ),
              ),
            ],
            if (widget.isChanging) ...[
              TextField(
                controller: _currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.settings_security_passphrase_current_label,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settings_security_passphrase_new_label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settings_security_passphrase_confirm_label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.settings_data_deletion_cancel_button,
            style: TextStyle(color: DesignColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.primary(context),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _handleSave,
          child: Text(l10n.settings_security_save_button),
        ),
      ],
    );
  }
}

class _VerifyPassphraseDialog extends StatefulWidget {
  final String? currentStored;

  const _VerifyPassphraseDialog({required this.currentStored});

  @override
  State<_VerifyPassphraseDialog> createState() => _VerifyPassphraseDialogState();
}

class _VerifyPassphraseDialogState extends State<_VerifyPassphraseDialog> {
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
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: DesignColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: DesignColors.primary(context), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.settings_security_verify_passphrase_dialog_title,
              style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settings_security_passphrase_verify_desc,
            style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.settings_cloud_sync_passphrase_label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            l10n.settings_data_deletion_cancel_button,
            style: TextStyle(color: DesignColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.primary(context),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final entered = _controller.text.trim();
            final matches = entered == widget.currentStored;
            Navigator.of(context).pop(matches);
          },
          child: Text(l10n.settings_security_verify_button),
        ),
      ],
    );
  }
}
