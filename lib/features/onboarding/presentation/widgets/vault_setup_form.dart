import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/vault_service.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../shared/widgets/prism_toast.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/onboarding_provider.dart';
import '../../../../core/utils/storage_permission_helper.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/config/app_config.dart';
import 'package:prism/l10n/l10n.dart';

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
  late String _selectedVaultType;
  String _customLocationPath = '';
  bool _isPickingFolder = false;
  bool _isCompleting = false;
  bool _shareAnalytics = false;
  late int _currentStep; // 1: Main Storage Location, 2: First Vault Name, 3: Privacy Preferences
  bool _isAutoImport = false;
  String _autoImportHubPath = '';
  String _autoImportActiveVault = '';

  final TextEditingController _hubNameController = TextEditingController();
  final TextEditingController _vaultNameController = TextEditingController();
  bool _didInitControllers = false;

  @override
  void initState() {
    super.initState();
    _selectedVaultType = AppConfig.enableExternalStorage ? 'custom' : 'sandbox';
    _currentStep = AppConfig.enableExternalStorage ? 1 : 2;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitControllers) {
      _hubNameController.text = context.l10n.onboarding_vault_setup_default_hub_name;
      _vaultNameController.text = context.l10n.onboarding_vault_setup_default_vault_name;
      _didInitControllers = true;
    }
  }

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
      PrismToast.show(
        context,
        context.l10n.onboarding_vault_setup_folder_picker_error(e.toString()),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isPickingFolder = false);
    }
  }

  Future<void> _handleNextStep() async {
    if (kDebugMode) {
      debugPrint('DEBUG: _handleNextStep started');
    }
    if (_selectedVaultType == 'sandbox') {
      setState(() {
        _currentStep = 2;
      });
      return;
    }
    final hubName = _hubNameController.text.trim();
    if (hubName.isEmpty) {
      if (kDebugMode) {
        debugPrint('DEBUG: hubName is empty');
      }
      PrismToast.show(
        context,
        context.l10n.onboarding_vault_setup_name_required_error,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }
    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
    if (!safePattern.hasMatch(hubName)) {
      if (kDebugMode) {
        debugPrint('DEBUG: hubName does not match safePattern');
      }
      PrismToast.show(
        context,
        context.l10n.onboarding_vault_setup_invalid_chars_error,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (_customLocationPath.isEmpty) {
      if (kDebugMode) {
        debugPrint('DEBUG: _customLocationPath is empty');
      }
      PrismToast.show(
        context,
        context.l10n.onboarding_vault_setup_folder_required_error,
        icon: Icons.folder_open_rounded,
      );
      return;
    }

    // Check and request storage permission immediately for custom vaults
    final hasAccess = await StoragePermissionHelper.hasAllFilesAccess();
    if (kDebugMode) {
      debugPrint('DEBUG: hasAccess = $hasAccess');
    }
    if (!mounted) {
      if (kDebugMode) {
        debugPrint('DEBUG: not mounted after permission check');
      }
      return;
    }
    if (!hasAccess) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: DesignColors.surface(context),
          title: Text(
            context.l10n.onboarding_vault_setup_permission_title,
            style: DesignTypography.heading(context, fontWeight: FontWeight.bold),
          ),
          content: Text(
            context.l10n.onboarding_vault_setup_permission_desc,
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
        if (!mounted) return;
        PrismToast.show(
          context,
          context.l10n.onboarding_vault_setup_permission_retry_desc,
          icon: Icons.info_outline_rounded,
        );
      }
      return;
    }

    // Check if Prism Hub directory already exists and contains existing vaults (subfolders)
    final hubPath = p.join(_customLocationPath, hubName);
    final hubDir = Directory(hubPath);
    final hubExists = await hubDir.exists();
    if (kDebugMode) {
      debugPrint('DEBUG: hubPath = $hubPath, exists = $hubExists');
    }
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
        if (kDebugMode) {
          debugPrint('Error scanning existing hub: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('DEBUG: subDirs count = ${subDirs.length}');
      }
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
              if (dbTime.isAfter(subDirLatest)) {
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

        if (kDebugMode) {
          debugPrint('DEBUG: existing vaults found. Active vault = $activeVault. Transitioning to step 3...');
        }
        
        setState(() {
          _isAutoImport = true;
          _autoImportHubPath = hubPath;
          _autoImportActiveVault = activeVault;
          _currentStep = 3;
        });
        return;
      }
    }

    if (kDebugMode) {
      debugPrint('DEBUG: no existing vaults, transitioning to step 2');
    }
    // No existing vaults, proceed to Step 2
    setState(() {
      if (kDebugMode) {
        debugPrint('DEBUG: setState for step 2 called');
      }
      _isAutoImport = false;
      _currentStep = 2;
    });
  }

  Future<void> _completeOnboarding() async {
    if (kDebugMode) {
      debugPrint('DEBUG: _completeOnboarding started');
    }
    if (_isCompleting) {
      if (kDebugMode) {
        debugPrint('DEBUG: already completing, returning');
      }
      return;
    }

    setState(() => _isCompleting = true);

    // Capture everything from ref BEFORE calling widget.onStartSetup()
    final onboardingNotifier = ref.read(onboardingStateProvider.notifier);
    final baseVaultsDirNotifier = ref.read(baseVaultsDirectoryProvider.notifier);
    final activeVaultNameNotifier = ref.read(activeVaultNameProvider.notifier);
    final prefs = ref.read(sharedPreferencesProvider);
    final analyticsEnabledNotifier = ref.read(analyticsEnabledProvider.notifier);
    final vaultService = ref.read(vaultManagementServiceProvider);

    if (kDebugMode) {
      debugPrint('DEBUG: calling onStartSetup()');
    }
    widget.onStartSetup();

    try {
      if (_isAutoImport) {
        if (widget.onPersist != null) {
          await widget.onPersist!(_autoImportHubPath, _autoImportActiveVault, _selectedVaultType);
        } else {
          await prefs.setString('vaultType', _selectedVaultType);
          await analyticsEnabledNotifier.setEnabled(_shareAnalytics);
          await baseVaultsDirNotifier.setDirectory(_autoImportHubPath);
          await activeVaultNameNotifier.setVaultName(_autoImportActiveVault);

          await vaultService.closeDatabase();
          AnalyticsService.logEvent('onboarding_complete', parameters: {
            'vault_type': _selectedVaultType,
            'import': true,
          });
          await onboardingNotifier.completeOnboarding();
        }

        if (mounted) {
          final hubName = p.basename(_autoImportHubPath);
          PrismToast.show(
            context,
            context.l10n.onboarding_vault_setup_import_success(hubName, _autoImportActiveVault),
            icon: Icons.check_circle_outline_rounded,
          );
        }
      } else {
        final vaultName = _vaultNameController.text.trim().isEmpty
            ? 'My Vault'
            : _vaultNameController.text.trim();

        final String hubPath;
        final String effectiveVaultType = AppConfig.enableExternalStorage ? _selectedVaultType : 'sandbox';
        if (effectiveVaultType == 'sandbox') {
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
          await widget.onPersist!(hubPath, vaultName, effectiveVaultType);
        } else {
          await prefs.setString('vaultType', effectiveVaultType);
          
          // Save analytics choice and toggle Firebase collections
          await analyticsEnabledNotifier.setEnabled(_shareAnalytics);

          await baseVaultsDirNotifier.setDirectory(hubPath);
          await activeVaultNameNotifier.setVaultName(vaultName);

          await vaultService.closeDatabase();
          AnalyticsService.logEvent('onboarding_complete', parameters: {
            'vault_type': effectiveVaultType,
            'import': false,
          });
          await onboardingNotifier.completeOnboarding();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during vault initialization: $e');
      }
      if (mounted) {
        setState(() => _isCompleting = false);
        widget.onEndSetup();
        PrismToast.show(
          context,
          context.l10n.onboarding_vault_setup_setup_error(e.toString()),
          icon: Icons.error_outline_rounded,
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
            _currentStep == 1
                ? context.l10n.onboarding_vault_setup_config_location_title
                : (_currentStep == 2
                    ? context.l10n.onboarding_vault_setup_name_vault_title
                    : context.l10n.onboarding_vault_setup_privacy_title),
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
                ? context.l10n.onboarding_vault_setup_choose_location_desc
                : (_currentStep == 2
                    ? context.l10n.onboarding_vault_setup_first_vault_desc
                    : context.l10n.onboarding_vault_setup_privacy_desc),
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
              context.l10n.onboarding_vault_setup_vault_location_label,
              style: DesignTypography.body(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textStyle,
              ),
            ).animate().fadeIn(delay: 210.ms).slideY(begin: 0.15),
            const SizedBox(height: 10),
            
            RadioGroup<String>(
              groupValue: _selectedVaultType,
              onChanged: (val) {
                if (val != null) setState(() => _selectedVaultType = val);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Radio<String>(
                            value: 'custom',
                            // ignore: deprecated_member_use
                            groupValue: _selectedVaultType,
                            // ignore: deprecated_member_use
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedVaultType = val);
                            },
                            activeColor: colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      context.l10n.onboarding_vault_setup_device_storage_label,
                                      style: DesignTypography.body(
                                        context,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: textStyle,
                                      ),
                                    ),
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
                                const SizedBox(height: 6),
                                Text(
                                  '• ${context.l10n.onboarding_vault_setup_device_storage_desc}',
                                  style: DesignTypography.details(context, color: textSecStyle),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Radio<String>(
                            value: 'sandbox',
                            // ignore: deprecated_member_use
                            groupValue: _selectedVaultType,
                            // ignore: deprecated_member_use
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedVaultType = val);
                            },
                            activeColor: colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.onboarding_vault_setup_app_storage_label,
                                  style: DesignTypography.body(
                                    context,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: textStyle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• ${context.l10n.onboarding_vault_setup_app_storage_desc_android}',
                                  style: DesignTypography.details(context, color: textSecStyle),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• ${context.l10n.onboarding_vault_setup_app_storage_desc_warning}',
                                  style: DesignTypography.details(context, color: textSecStyle),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 240.ms),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (_selectedVaultType == 'custom') ...[
              // ── Step 1: Prism Hub Name ──────────────────────────────────────
              Text(
                context.l10n.onboarding_vault_setup_hub_name_label,
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
                  hintText: context.l10n.onboarding_vault_setup_hub_name_hint,
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
                                  semanticsLabel: 'Loading',
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
                                        ? context.l10n.onboarding_vault_setup_location_selected
                                        : context.l10n.onboarding_vault_setup_choose_folder_prompt,
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
                                  : context.l10n.onboarding_vault_setup_location_creation_desc,
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
                  context.l10n.onboarding_vault_setup_choose_folder_warning,
                  style: DesignTypography.details(
                    context,
                    fontSize: 12,
                    color: DesignColors.textTertiary(context),
                  ),
                ),
              ),
            ],
          ] else if (_currentStep == 2) ...[
            // ── Step 2: Vault Name ──────────────────────────────────────────
            Text(
              context.l10n.onboarding_vault_setup_vault_name_label,
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
                hintText: context.l10n.onboarding_vault_setup_vault_name_hint,
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
            const SizedBox(height: 32),
            // Next Button
            DesignPrimaryButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              onTap: !_isCompleting ? () {
                final vaultName = _vaultNameController.text.trim().isEmpty
                    ? 'My Vault'
                    : _vaultNameController.text.trim();
                final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
                if (!safePattern.hasMatch(vaultName)) {
                  PrismToast.show(
                    context,
                    context.l10n.onboarding_vault_setup_invalid_chars_error,
                    icon: Icons.warning_amber_rounded,
                  );
                  return;
                }
                setState(() {
                  _isAutoImport = false;
                  _currentStep = 3;
                });
              } : null,
            ).animate().fadeIn(delay: 280.ms),
            if (AppConfig.enableExternalStorage) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: Text(
                    context.l10n.onboarding_vault_setup_back_button,
                    style: DesignTypography.details(
                      context,
                      color: DesignColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ] else if (_currentStep == 3) ...[
            // ── Step 3: Privacy & Telemetry ─────────────────────────────────
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
                          context.l10n.onboarding_vault_setup_telemetry_title,
                          style: DesignTypography.body(
                            context,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textStyle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.onboarding_vault_setup_telemetry_desc,
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
                    activeThumbColor: colorScheme.primary,
                    onChanged: (val) {
                      setState(() => _shareAnalytics = val);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            // Legal Assent Notice
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text.rich(
                  TextSpan(
                    text: context.l10n.onboarding_legal_assent_pre,
                    style: DesignTypography.details(
                      context,
                      fontSize: 11,
                      color: DesignColors.textSecondary(context),
                    ).copyWith(height: 1.45),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => context.push('/settings/terms'),
                          child: Text(
                            context.l10n.onboarding_legal_terms_link,
                            style: DesignTypography.details(
                              context,
                              fontSize: 11,
                              color: colorScheme.primary,
                            ).copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: context.l10n.onboarding_legal_and,
                        style: DesignTypography.details(
                          context,
                          fontSize: 11,
                          color: DesignColors.textSecondary(context),
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => context.push('/settings/privacy-policy'),
                          child: Text(
                            context.l10n.onboarding_legal_privacy_link,
                            style: DesignTypography.details(
                              context,
                              fontSize: 11,
                              color: colorScheme.primary,
                            ).copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ).animate().fadeIn(delay: 210.ms),
            const SizedBox(height: 16),
            // Confirm & Begin Button
            DesignPrimaryButton(
              label: context.l10n.onboarding_vault_setup_confirm_button,
              icon: Icons.check_rounded,
              onTap: !_isCompleting ? _completeOnboarding : null,
            ).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    if (_isAutoImport) {
                      _isAutoImport = false;
                      _currentStep = 1;
                    } else {
                      _currentStep = 2;
                    }
                  });
                },
                child: Text(
                  _isAutoImport
                      ? context.l10n.onboarding_vault_setup_back_button
                      : context.l10n.onboarding_vault_setup_back_button_step2,
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
