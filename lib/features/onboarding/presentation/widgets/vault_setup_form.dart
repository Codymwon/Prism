import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/onboarding_provider.dart';

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
  String _customLocationPath = '';
  final TextEditingController _vaultNameController = TextEditingController(text: 'My Vault');

  @override
  void dispose() {
    _vaultNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomLocation() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
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
    }
  }

  Future<void> _completeOnboarding() async {
    widget.onStartSetup();

    try {
      final baseDir = _customLocationPath;
      final vaultName = _vaultNameController.text.trim().isEmpty 
          ? 'My Vault' 
          : _vaultNameController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('baseVaultsDirectory', baseDir);
      await prefs.setString('activeVaultName', vaultName);

      // Force database helper to close old global DB connection (if any)
      await DatabaseHelper.instance.closeDatabase();

      // Save onboarding complete state
      await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    } catch (e) {
      debugPrint('Error during vault initialization: $e');
      // Fallback: save onboarding state anyway so user is not stuck
      await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    } finally {
      widget.onEndSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = DesignColors.surface(context);
    final cardBorder = DesignColors.border(context);
    final textStyle = DesignColors.text(context);
    final textSecStyle = DesignColors.textSecondary(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header
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
            'Meridian stores all your notes directly on your device. Choose where your vault folder lives. You can create and switch between multiple vaults later.',
            style: DesignTypography.body(
              context,
              fontSize: 14,
              height: 1.6,
              color: textSecStyle,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),

          // Vault Name input
          Text(
            'Initial Vault Name',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textStyle,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _vaultNameController,
            style: DesignTypography.body(context, fontSize: 14, color: textStyle),
            decoration: InputDecoration(
              filled: true,
              fillColor: DesignColors.surfaceVariant(context),
              hintText: 'e.g. My Vault, Personal, Research',
              hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: colorScheme.primary),
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 28),

          Text(
            'Storage Directory Location',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textStyle,
            ),
          ),
          const SizedBox(height: 12),

          // High-fidelity Folder Picker Card
          TactileWrapper(
            style: TactileFeedbackStyle.standard,
            onTap: _pickCustomLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _customLocationPath.isNotEmpty ? colorScheme.primary : cardBorder,
                  width: _customLocationPath.isNotEmpty ? 2 : 1,
                ),
                boxShadow: _customLocationPath.isNotEmpty
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _customLocationPath.isNotEmpty
                          ? colorScheme.primaryContainer
                          : cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _customLocationPath.isNotEmpty
                          ? Icons.folder_rounded
                          : Icons.create_new_folder_outlined,
                      color: _customLocationPath.isNotEmpty
                          ? colorScheme.primary
                          : textSecStyle,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _customLocationPath.isNotEmpty
                                  ? 'Storage Location Configured'
                                  : 'Select Storage Folder',
                              style: DesignTypography.body(
                                context,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textStyle,
                              ),
                            ),
                            if (_customLocationPath.isNotEmpty)
                              Text(
                                'Change',
                                style: DesignTypography.body(
                                  context,
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _customLocationPath.isNotEmpty
                              ? _customLocationPath
                              : 'Tap to choose where your vault folder lives on your device. Meridian will store all notes here.',
                          style: DesignTypography.details(
                            context,
                            fontSize: 13,
                            color: _customLocationPath.isNotEmpty ? textStyle : textSecStyle,
                          ).copyWith(height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),

          // Confirm Action Button
          DesignPrimaryButton(
            label: _customLocationPath.isEmpty
                ? 'Select Storage Folder'
                : 'Confirm & Initialize Workspace',
            onTap: _customLocationPath.isEmpty
                ? _pickCustomLocation
                : () {
                    final vaultName = _vaultNameController.text.trim();
                    if (vaultName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid name for your vault.')),
                      );
                      return;
                    }
                    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
                    if (!safePattern.hasMatch(vaultName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vault name can only contain letters, numbers, spaces, underscores, and hyphens.')),
                      );
                      return;
                    }
                    _completeOnboarding();
                  },
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}
