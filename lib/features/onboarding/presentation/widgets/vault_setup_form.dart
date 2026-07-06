import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/onboarding_provider.dart';
import '../../data/tutorial_provider.dart';
import '../../../../core/utils/storage_permission_helper.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/database/vault_providers.dart';

class VaultSetupForm extends ConsumerStatefulWidget {
  final VoidCallback onStartSetup;
  final VoidCallback onEndSetup;

  /// Optional override for the persistence step (saving prefs, closing DB,
  /// marking onboarding complete). When null the widget uses the real
  /// Riverpod / DatabaseHelper implementation. Pass a no-op in tests.
  final Future<void> Function(String hubPath, String activeVault, String vaultType)? onPersist;

  const VaultSetupForm({
    super.key,
    required this.onStartSetup,
    required this.onEndSetup,
    this.onPersist,
  });

  @override
  ConsumerState<VaultSetupForm> createState() => _VaultSetupFormState();
}

class _VaultSetupFormState extends ConsumerState<VaultSetupForm> {
  String _selectedVaultType = 'custom';
  String _customLocationPath = '';
  bool _isPickingFolder = false;
  bool _isCompleting = false;
  bool _shareAnalytics = true;
  int _currentStep = 1; // 1: Main Storage Location, 2: First Vault Name

  final TextEditingController _hubNameController =
      TextEditingController(text: 'Prism Hub');
  final TextEditingController _vaultNameController =
      TextEditingController(text: 'My Vault');

  @override
  void dispose() {
    _hubNameController.dispose();
    _vaultNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomLocation() async {
    if (_isPickingFolder) return;

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

  Future<void> _handleNextStep() async {
    print('DEBUG: _handleNextStep started');
    if (_selectedVaultType == 'sandbox') {
      setState(() {
        _currentStep = 2;
      });
      return;
    }
    final hubName = _hubNameController.text.trim();
    if (hubName.isEmpty) {
      print('DEBUG: hubName is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the main folder.')),
      );
      return;
    }
    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
    if (!safePattern.hasMatch(hubName)) {
      print('DEBUG: hubName does not match safePattern');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Folder name can only contain letters, numbers, spaces, underscores, and hyphens.',
          ),
        ),
      );
      return;
    }

    if (_customLocationPath.isEmpty) {
      print('DEBUG: _customLocationPath is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a storage folder.')),
      );
      return;
    }

    // Check and request storage permission immediately for custom vaults
    final hasAccess = await StoragePermissionHelper.hasAllFilesAccess();
    print('DEBUG: hasAccess = $hasAccess');
    if (!mounted) {
      print('DEBUG: not mounted after permission check');
      return;
    }
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
              content: Text('Please enable All Files Access for Prism and tap Next again.'),
            ),
          );
        }
      }
      return;
    }

    // Check if Prism Hub directory already exists and contains existing vaults (subfolders)
    final hubPath = p.join(_customLocationPath, hubName);
    final hubDir = Directory(hubPath);
    final hubExists = await hubDir.exists();
    print('DEBUG: hubPath = $hubPath, exists = $hubExists');
    if (hubExists) {
      List<Directory> subDirs = [];
      try {
        final list = await hubDir.list().toList();
        for (final entity in list) {
          if (entity is Directory && !p.basename(entity.path).startsWith('.')) {
            subDirs.add(entity);
          }
        }
      } catch (e) {
        debugPrint('Error scanning existing hub: $e');
      }

      print('DEBUG: subDirs count = ${subDirs.length}');
      if (subDirs.isNotEmpty) {
        // Find most recently modified vault based on file/db timestamps
        Directory? mostRecentDir;
        DateTime? latestTime;
        for (final subDir in subDirs) {
          DateTime? subDirLatest;
          try {
            final stat = await subDir.stat();
            subDirLatest = stat.modified;
            final dbFile = File(p.join(subDir.path, '.prism.db'));
            if (await dbFile.exists()) {
              final dbTime = await dbFile.lastModified();
              if (subDirLatest != null && dbTime.isAfter(subDirLatest)) {
                subDirLatest = dbTime;
              }
            }
          } catch (e) {
            // Ignore
          }
          if (subDirLatest != null) {
            if (latestTime == null || subDirLatest.isAfter(latestTime)) {
              latestTime = subDirLatest;
              mostRecentDir = subDir;
            }
          }
        }

        final activeVault = mostRecentDir != null
            ? p.basename(mostRecentDir.path)
            : p.basename(subDirs.first.path);

        print('DEBUG: existing vaults found. Active vault = $activeVault. Auto-importing...');
        // Auto-import and bypass Step 2 entirely
        setState(() => _isCompleting = true);
        widget.onStartSetup();

        try {
          if (widget.onPersist != null) {
            await widget.onPersist!(hubPath, activeVault, _selectedVaultType);
          } else {
            final onboardingNotifier = ref.read(onboardingStateProvider.notifier);
            final baseVaultsDirNotifier = ref.read(baseVaultsDirectoryProvider.notifier);
            final activeVaultNameNotifier = ref.read(activeVaultNameProvider.notifier);

            final prefs = ref.read(sharedPreferencesProvider);
            await prefs.setString('vaultType', _selectedVaultType);
            await baseVaultsDirNotifier.setDirectory(hubPath);
            await activeVaultNameNotifier.setVaultName(activeVault);

            await DatabaseHelper.instance.closeDatabase();
            await onboardingNotifier.completeOnboarding();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Found existing vaults in "$hubName". Imported and opened "$activeVault".',
                ),
              ),
            );
          }
          return;
        } catch (e) {
          debugPrint('Error importing existing vaults: $e');
          if (mounted) {
            setState(() => _isCompleting = false);
            widget.onEndSetup();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Import failed: $e. Please try again.')),
            );
          }
          return;
        }
      }
    }

    print('DEBUG: no existing vaults, transitioning to step 2');
    // No existing vaults, proceed to Step 2
    setState(() {
      print('DEBUG: setState for step 2 called');
      _currentStep = 2;
    });
  }

  Future<void> _completeOnboarding() async {
    print('DEBUG: _completeOnboarding started');
    if (_isCompleting) {
      print('DEBUG: already completing, returning');
      return;
    }

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

    setState(() => _isCompleting = true);

    final onboardingNotifier = ref.read(onboardingStateProvider.notifier);
    final baseVaultsDirNotifier = ref.read(baseVaultsDirectoryProvider.notifier);
    final activeVaultNameNotifier = ref.read(activeVaultNameProvider.notifier);

    print('DEBUG: calling onStartSetup()');
    widget.onStartSetup();

    try {
      final String hubPath;
      if (_selectedVaultType == 'sandbox') {
        final docDir = await getApplicationDocumentsDirectory();
        hubPath = p.join(docDir.path, 'prism_vaults');
      } else {
        final hubName = _hubNameController.text.trim();
        hubPath = p.join(_customLocationPath, hubName);
      }
      final newVaultPath = p.join(hubPath, vaultName);

      // Ensure the physical directories exist
      final vaultDir = Directory(newVaultPath);
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      if (widget.onPersist != null) {
        await widget.onPersist!(hubPath, vaultName, _selectedVaultType);
      } else {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('vaultType', _selectedVaultType);
        
        // Save analytics choice and toggle Firebase collections
        await ref.read(analyticsEnabledProvider.notifier).setEnabled(_shareAnalytics);

        await baseVaultsDirNotifier.setDirectory(hubPath);
        await activeVaultNameNotifier.setVaultName(vaultName);

        await DatabaseHelper.instance.closeDatabase();
        AnalyticsService.logEvent('onboarding_complete', parameters: {
          'vault_type': _selectedVaultType,
        });
        await onboardingNotifier.completeOnboarding();
      }
    } catch (e) {
      debugPrint('Error during vault initialization: $e');
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
            _currentStep == 1 ? 'Configure Vault Location' : 'Name your first vault',
            style: DesignTypography.display(
              context,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textStyle,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            _currentStep == 1
                ? 'Prism stores all your notes directly on your device. Choose where your main storage folder (Prism Hub) lives. You can switch between multiple vaults later.'
                : 'This will be your first workspace folder created inside the main directory.',
            style: DesignTypography.body(
              context,
              fontSize: 14,
              height: 1.6,
              color: textSecStyle,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),

          if (_currentStep == 1) ...[
            // ── Vault Location Selector ─────────────────────────────────────
            Text(
              'Vault Location',
              style: DesignTypography.body(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textStyle,
              ),
            ).animate().fadeIn(delay: 210.ms).slideY(begin: 0.15),
            const SizedBox(height: 10),
            
            // Device Storage Card
            GestureDetector(
              onTap: () => setState(() => _selectedVaultType = 'custom'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedVaultType == 'custom'
                      ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedVaultType == 'custom'
                        ? colorScheme.primary
                        : cardBorder,
                    width: _selectedVaultType == 'custom' ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: 'custom',
                          groupValue: _selectedVaultType,
                          activeColor: colorScheme.primary,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedVaultType = val);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Device storage',
                          style: DesignTypography.body(
                            context,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: DesignTypography.body(context, color: textSecStyle)),
                              Expanded(
                                child: Text(
                                  'Allows Prism data to be accessed by other apps.',
                                  style: DesignTypography.details(context, color: textSecStyle),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 12),

            // App Storage Card
            GestureDetector(
              onTap: () => setState(() => _selectedVaultType = 'sandbox'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedVaultType == 'sandbox'
                      ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedVaultType == 'sandbox'
                        ? colorScheme.primary
                        : cardBorder,
                    width: _selectedVaultType == 'sandbox' ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: 'sandbox',
                          groupValue: _selectedVaultType,
                          activeColor: colorScheme.primary,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedVaultType = val);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'App storage',
                          style: DesignTypography.body(
                            context,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textStyle,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: DesignTypography.body(context, color: textSecStyle)),
                              Expanded(
                                child: Text(
                                  'Your data will not be accessible to other apps.',
                                  style: DesignTypography.details(context, color: textSecStyle),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: DesignTypography.body(context, color: textSecStyle)),
                              Expanded(
                                child: Text(
                                  'Android will delete your data if you uninstall Prism.',
                                  style: DesignTypography.details(context, color: textSecStyle),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 230.ms),
            const SizedBox(height: 28),

            if (_selectedVaultType == 'custom') ...[
              // ── Step 1: Prism Hub Name ──────────────────────────────────────
              Text(
                'Prism Hub Name',
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textStyle,
                ),
              ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.15),
              const SizedBox(height: 8),
              TextField(
                controller: _hubNameController,
                style: DesignTypography.body(context, fontSize: 14, color: textStyle),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DesignColors.surfaceVariant(context),
                  hintText: 'e.g. Prism Hub, My Notes, Second Brain',
                  hintStyle: DesignTypography.body(
                    context,
                    color: DesignColors.textTertiary(context),
                  ),
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
                  prefixIcon: Icon(
                    Icons.folder_copy_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 28),

              // ── Step 1: Select Folder Location ──────────────────────────────
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
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.12),
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
                                  : 'Prism will create your main directory inside this folder.',
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
            ],
            // Next Button
            DesignPrimaryButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              onTap: (!_isCompleting && (_selectedVaultType == 'sandbox' || locationSelected)) ? _handleNextStep : null,
            ).animate().fadeIn(delay: 320.ms),
            if (_selectedVaultType == 'custom' && !locationSelected) ...[
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
          ] else ...[
            // ── Step 2: Vault Name ──────────────────────────────────────────
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
                  context,
                  color: DesignColors.textTertiary(context),
                ),
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
                prefixIcon: Icon(
                  Icons.drive_file_rename_outline_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),

            // Telemetry opt-out disclosure card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share anonymous telemetry',
                          style: DesignTypography.body(
                            context,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textStyle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Help us improve Prism by sharing anonymous feature usage data and crash logs. No personal data, notes, or search queries are ever collected.',
                          style: DesignTypography.details(
                            context,
                            fontSize: 12,
                            color: textSecStyle,
                          ).copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _shareAnalytics,
                    activeColor: colorScheme.primary,
                    onChanged: (val) {
                      setState(() => _shareAnalytics = val);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 260.ms),
            const SizedBox(height: 32),
            // Confirm & Begin Button
            DesignPrimaryButton(
              label: 'Confirm & Begin',
              icon: Icons.check_rounded,
              onTap: !_isCompleting ? _completeOnboarding : null,
            ).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: Text(
                  'Back to step 1',
                  style: DesignTypography.details(
                    context,
                    color: DesignColors.textSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
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

