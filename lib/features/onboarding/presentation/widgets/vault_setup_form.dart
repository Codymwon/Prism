import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/database/database_helper.dart';
import '../../../notes/data/note_repository.dart';
import '../../data/onboarding_provider.dart';
import '../../data/starter_notes.dart';

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
  bool _useDefaultLocation = true;
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
          _useDefaultLocation = false;
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
      final baseDir = _useDefaultLocation ? '' : _customLocationPath;
      final vaultName = _vaultNameController.text.trim().isEmpty 
          ? 'My Vault' 
          : _vaultNameController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('baseVaultsDirectory', baseDir);
      await prefs.setString('activeVaultName', vaultName);

      // Force database helper to close old global DB connection (if any)
      await DatabaseHelper.instance.closeDatabase();

      final repo = ref.read(noteRepositoryProvider);

      // Create starter notes inside the new vault directory
      await repo.createNote(
        title: 'Welcome to Meridian',
        initialContent: StarterNotes.welcomeNoteContent,
      );

      await repo.createNote(
        title: 'Getting Started with Wikilinks',
        initialContent: StarterNotes.wikilinksNoteContent,
      );

      await repo.createNote(
        title: 'The Magic of Daily Journaling',
        initialContent: StarterNotes.journalNoteContent,
      );

      // Save onboarding complete state
      await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    } catch (e) {
      debugPrint('Error creating starter notes: $e');
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

          // Selection Cards
          Column(
            children: [
              // Card 1: Default
              TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: () => setState(() => _useDefaultLocation = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _useDefaultLocation ? colorScheme.primary : cardBorder,
                      width: _useDefaultLocation ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _useDefaultLocation ? colorScheme.primaryContainer : cardBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.offline_pin_outlined, color: _useDefaultLocation ? colorScheme.primary : textSecStyle, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default Storage (Recommended)',
                              style: DesignTypography.body(context, fontWeight: FontWeight.w600, fontSize: 14, color: textStyle),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recommended. Kept safe in the app\'s internal documents sandbox folder.',
                              style: DesignTypography.details(context, fontSize: 12, color: textSecStyle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card 2: Custom
              TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: () async {
                  if (_useDefaultLocation) {
                    await _pickCustomLocation();
                  } else {
                    setState(() => _useDefaultLocation = false);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !_useDefaultLocation ? colorScheme.primary : cardBorder,
                      width: !_useDefaultLocation ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !_useDefaultLocation ? colorScheme.primaryContainer : cardBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.create_new_folder_outlined, color: !_useDefaultLocation ? colorScheme.primary : textSecStyle, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Custom Local Folder',
                                  style: DesignTypography.body(context, fontWeight: FontWeight.w600, fontSize: 14, color: textStyle),
                                ),
                                if (!_useDefaultLocation)
                                  GestureDetector(
                                    onTap: _pickCustomLocation,
                                    child: Text(
                                      'Change',
                                      style: DesignTypography.body(context, fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              !_useDefaultLocation && _customLocationPath.isNotEmpty
                                  ? _customLocationPath
                                  : 'Select any local folder (perfect for syncing with Obsidian, Syncthing, etc.)',
                              style: DesignTypography.details(context, fontSize: 12, color: textSecStyle),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),

          // Confirm Action Button
          DesignPrimaryButton(
            label: (!_useDefaultLocation && _customLocationPath.isEmpty)
                ? 'Select Custom Directory'
                : 'Confirm & Initialize Workspace',
            onTap: (!_useDefaultLocation && _customLocationPath.isEmpty)
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
