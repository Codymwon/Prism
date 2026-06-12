import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/storage_permission_helper.dart';
import '../../data/onboarding_provider.dart';
import '../../../../core/database/vault_providers.dart';

class VaultSetupForm extends ConsumerStatefulWidget {
  final VoidCallback onStartSetup;
  final VoidCallback onEndSetup;

  const VaultSetupForm({
    super.key,
    required this.onStartSetup,
    required this.onEndSetup,
  });

  @override
  ConsumerState<VaultSetupForm> createState() => _VaultSetupFormState();
}

class _VaultSetupFormState extends ConsumerState<VaultSetupForm> {
  final String _selectedVaultType = 'custom';
  String _customLocationPath = '';
  bool _isPickingFolder = false;
  bool _isCompleting = false;
  final TextEditingController _vaultNameController =
      TextEditingController(text: 'My Vault');

  @override
  void dispose() {
    _vaultNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomLocation() async {
    if (_isPickingFolder) return; // Prevent double-trigger

    setState(() => _isPickingFolder = true);

    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (!mounted) return;
      if (path != null) {
        setState(() {
          _customLocationPath = path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open folder picker: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPickingFolder = false);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return; // Prevent double-submission

    final vaultName = _vaultNameController.text.trim().isEmpty
        ? 'My Vault'
        : _vaultNameController.text.trim();
    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
    if (!safePattern.hasMatch(vaultName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vault name can only contain letters, numbers, spaces, underscores, and hyphens.',
          ),
        ),
      );
      return;
    }

    if (_selectedVaultType == 'custom') {
      if (_customLocationPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a storage folder.')),
        );
        return;
      }

      // Check and request storage permission immediately for custom vaults
      final hasAccess = await StoragePermissionHelper.hasAllFilesAccess();
      if (!mounted) return;
      if (!hasAccess) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: DesignColors.surface(context),
            title: Text(
              'Storage Access Required',
              style: DesignTypography.heading(context, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'To write and sync note files inside your chosen documents folder, Android requires the "All Files Access" permission.',
              style: DesignTypography.body(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: DesignTypography.details(context)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Settings', style: DesignTypography.details(context, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (proceed == true) {
          await StoragePermissionHelper.requestAllFilesAccess();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable All Files Access for Prism and tap Confirm again.'),
              ),
            );
          }
        }
        return;
      }
    }

    setState(() => _isCompleting = true);

    // Capture notifier references synchronously before widget.onStartSetup() —
    // the widget gets disposed when OnboardingScreen switches to OnboardingLoading,
    // at which point accessing `ref` directly would throw.
    final onboardingNotifier = ref.read(onboardingStateProvider.notifier);
    final baseVaultsDirNotifier = ref.read(baseVaultsDirectoryProvider.notifier);
    final activeVaultNameNotifier = ref.read(activeVaultNameProvider.notifier);

    widget.onStartSetup();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vaultType', _selectedVaultType);
      await baseVaultsDirNotifier.setDirectory(_customLocationPath);
      await activeVaultNameNotifier.setVaultName(vaultName);

      // Close any existing database connection before re-initialising.
      await DatabaseHelper.instance.closeDatabase();

      // Mark onboarding complete — GoRouter's redirect listener automatically
      // navigates to /notes. Do NOT call onEndSetup on success; calling
      // setState after the router navigates away rebuilds the form with reset
      // local state, causing the "screen resets" bug.
      await onboardingNotifier.completeOnboarding();
    } catch (e) {
      debugPrint('Error during vault initialization: $e');
      // On failure: reset loading state so the user can retry.
      if (mounted) {
        setState(() => _isCompleting = false);
        widget.onEndSetup();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = DesignColors.surface(context);
    final cardBorder = DesignColors.border(context);
    final textStyle = DesignColors.text(context);
    final textSecStyle = DesignColors.textSecondary(context);

    final bool locationSelected = _customLocationPath.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Text(
            'CREATE YOUR WORKSPACE',
            style: DesignTypography.metadata(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Configure Vault Location',
            style: DesignTypography.display(
              context,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textStyle,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Prism stores all your notes directly on your device. Choose where your vault folder lives. You can switch between multiple vaults later.',
            style: DesignTypography.body(
              context,
              fontSize: 14,
              height: 1.6,
              color: textSecStyle,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),

          // ── Vault Name ────────────────────────────────────────────────────
          Text(
            'Vault Name',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textStyle,
            ),
          ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.15),
          const SizedBox(height: 8),
          TextField(
            controller: _vaultNameController,
            style: DesignTypography.body(context, fontSize: 14, color: textStyle),
            decoration: InputDecoration(
              filled: true,
              fillColor: DesignColors.surfaceVariant(context),
              hintText: 'e.g. My Vault, Personal, Research',
              hintStyle: DesignTypography.body(
                  context, color: DesignColors.textTertiary(context)),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.drive_file_rename_outline_rounded,
                  size: 18, color: colorScheme.primary),
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 28),

          // ── Select Folder Location ──
          Text(
            'Select Folder Location',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textStyle,
            ),
          ).animate().fadeIn(delay: 270.ms).slideY(begin: 0.15),
          const SizedBox(height: 10),
          TactileWrapper(
            style: TactileFeedbackStyle.standard,
            onTap: _isPickingFolder ? null : _pickCustomLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: locationSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                    : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: locationSelected ? colorScheme.primary : cardBorder,
                  width: locationSelected ? 2 : 1,
                ),
                boxShadow: locationSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: locationSelected
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isPickingFolder
                        ? Padding(
                            padding: const EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            locationSelected
                                ? Icons.folder_rounded
                                : Icons.folder_open_rounded,
                            color: locationSelected
                                ? colorScheme.primary
                                : textSecStyle,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                locationSelected
                                    ? 'Location selected'
                                    : 'Tap to choose a folder',
                                style: DesignTypography.body(
                                  context,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: locationSelected
                                      ? colorScheme.primary
                                      : textStyle,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (locationSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Change',
                                    style: DesignTypography.metadata(
                                      context,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationSelected
                              ? _customLocationPath
                              : 'Prism will store all your notes inside this folder.',
                          style: DesignTypography.details(
                            context,
                            fontSize: 12,
                            color: locationSelected
                                ? textSecStyle
                                : DesignColors.textTertiary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 290.ms),

          const SizedBox(height: 32),

          // ── Single Confirm Button ──
          DesignPrimaryButton(
            label: 'Confirm & Begin',
            icon: Icons.check_rounded,
            onTap: (!_isCompleting && locationSelected)
                ? _completeOnboarding
                : null,
          ).animate().fadeIn(delay: 320.ms),

          if (!locationSelected) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Choose a storage folder above to continue',
                style: DesignTypography.details(
                  context,
                  fontSize: 12,
                  color: DesignColors.textTertiary(context),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
