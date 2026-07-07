import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/services/vault_service.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../folders/presentation/providers/folders_providers.dart';
import '../widgets/settings_widgets.dart';

class ManageVaultsScreen extends ConsumerStatefulWidget {
  const ManageVaultsScreen({super.key});

  @override
  ConsumerState<ManageVaultsScreen> createState() => _ManageVaultsScreenState();
}

class _ManageVaultsScreenState extends ConsumerState<ManageVaultsScreen> {
  bool _isLoading = false;
  int _noteCount = 0;
  int _attachmentCount = 0;
  String _totalSizeStr = '0 KB';

  @override
  void initState() {
    super.initState();
    _loadActiveVaultStats();
  }

  Future<void> _loadActiveVaultStats() async {
    final activePath = ref.read(activeVaultPathProvider).valueOrNull ?? '';
    if (activePath.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final dir = Directory(activePath);
      if (await dir.exists()) {
        int notes = 0;
        int attachments = 0;
        int bytes = 0;

        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            final size = await entity.length();
            bytes += size;

            if (ext == '.md') {
              notes++;
            } else if (ext == '.m4a') {
              attachments++;
            }
          }
        }

        final sizeStr = _formatBytes(bytes);
        if (mounted) {
          setState(() {
            _noteCount = notes;
            _attachmentCount = attachments;
            _totalSizeStr = sizeStr;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading vault stats: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _changeHubLocation() async {
    final currentBaseDir = ref.read(baseVaultsDirectoryProvider).valueOrNull ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RelocationBottomSheet(
        currentBaseDir: currentBaseDir,
        onRelocate: (destPath, vaultType, migrateData) async {
          Navigator.pop(context); // Close bottom sheet
          
          setState(() => _isLoading = true);
          try {
            final String resolvedPath;
            if (vaultType == 'sandbox') {
              final docDir = await getApplicationDocumentsDirectory();
              resolvedPath = p.join(docDir.path, 'prism_vaults');
            } else {
              resolvedPath = destPath;
            }

            ref.read(selectedFolderIdProvider.notifier).state = null;
            await ref.read(vaultManagementServiceProvider).changeStorageLocation(
              newPath: resolvedPath,
              vaultType: vaultType,
              migrateData: migrateData,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    migrateData 
                        ? 'Storage location relocated and vaults migrated.' 
                        : 'Storage location changed.'
                  ),
                ),
              );
              _loadActiveVaultStats();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    'Error relocating storage: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _createVault() async {
    final controller = TextEditingController();
    final baseDir = ref.read(baseVaultsDirectoryProvider).valueOrNull ?? '';

    final vaultName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.surface(context),
        title: Text(
          'Create New Vault',
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Vault Name',
            hintText: 'e.g. Work, Personal',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: DesignColors.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (vaultName == null || vaultName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref.read(vaultManagementServiceProvider).createVault(
        vaultName: vaultName,
        baseDir: baseDir,
      );
      _loadActiveVaultStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create vault: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _renameVault(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final baseDir = ref.read(baseVaultsDirectoryProvider).valueOrNull ?? '';

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.surface(context),
        title: Text(
          'Rename Vault',
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: DesignColors.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newName == null || newName.isEmpty || newName == oldName) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(vaultManagementServiceProvider).renameVault(
        oldName: oldName,
        newName: newName,
        baseDir: baseDir,
      );
      _loadActiveVaultStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename vault: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteVault(String vaultName) async {
    final baseDir = ref.read(baseVaultsDirectoryProvider).valueOrNull ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.surface(context),
        title: Text(
          'Delete Vault "$vaultName"?',
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete this vault directory and all notes inside it from this device. This cannot be undone.',
          style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: DesignColors.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref.read(vaultManagementServiceProvider).deleteVault(
        vaultName: vaultName,
        baseDir: baseDir,
      );
      _loadActiveVaultStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete vault: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchVault(String vaultName) async {
    setState(() => _isLoading = true);
    try {
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref.read(vaultManagementServiceProvider).switchVault(
        vaultName: vaultName,
      );
      _loadActiveVaultStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to vault: $vaultName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch vault: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVaultName = ref.watch(activeVaultNameProvider).valueOrNull ?? '';
    final baseVaultsDir = ref.watch(baseVaultsDirectoryProvider).valueOrNull ?? '';
    final availableVaultsAsync = ref.watch(availableVaultsProvider);

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
          'Manage Vaults',
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
                  const SettingsSectionHeader(title: 'Physical Storage Location'),
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
                          Text(
                            'Prism Hub Location',
                            style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            baseVaultsDir.isEmpty ? 'Loading...' : baseVaultsDir,
                            style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignColors.primary(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.folder_open_rounded, size: 18),
                            label: const Text('Relocate Prism Hub'),
                            onPressed: _changeHubLocation,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SettingsSectionHeader(title: 'Active Vault Statistics'),
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
                          Text(
                            activeVaultName,
                            style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w700, color: DesignColors.primary(context)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Notes (.md)', style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context))),
                              Text('$_noteCount', style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Audio Attachments (.m4a)', style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context))),
                              Text('$_attachmentCount', style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Size on Disk', style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context))),
                              Text(_totalSizeStr, style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SettingsSectionHeader(title: 'All Local Vaults'),
                      IconButton(
                        icon: Icon(Icons.add_rounded, color: DesignColors.primary(context)),
                        onPressed: _createVault,
                        tooltip: 'Create New Vault',
                      ),
                    ],
                  ),
                  availableVaultsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading')),
                    error: (err, _) => Text('Error loading vaults: $err', style: const TextStyle(color: Colors.red)),
                    data: (vaults) {
                      return Column(
                        children: vaults.map((vault) {
                          final isActive = vault == activeVaultName;
                          return Card(
                            color: isActive 
                                ? DesignColors.primary(context).withValues(alpha: 0.05) 
                                : DesignColors.surface(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isActive 
                                    ? DesignColors.primary(context) 
                                    : DesignColors.text(context).withValues(alpha: 0.05),
                                width: isActive ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                vault,
                                style: DesignTypography.body(
                                  context, 
                                  fontSize: 14, 
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                isActive ? 'Active Vault' : 'Local Vault',
                                style: DesignTypography.body(
                                  context, 
                                  fontSize: 12, 
                                  color: isActive ? DesignColors.primary(context) : DesignColors.textSecondary(context),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isActive)
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                                      onPressed: () => _switchVault(vault),
                                      tooltip: 'Switch to this vault',
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _renameVault(vault),
                                    tooltip: 'Rename Vault',
                                  ),
                                  if (vaults.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                      onPressed: () => _deleteVault(vault),
                                      tooltip: 'Delete Vault',
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _RelocationBottomSheet extends StatefulWidget {
  final String currentBaseDir;
  final Function(String path, String vaultType, bool migrateData) onRelocate;

  const _RelocationBottomSheet({
    required this.currentBaseDir,
    required this.onRelocate,
  });

  @override
  State<_RelocationBottomSheet> createState() => _RelocationBottomSheetState();
}

class _RelocationBottomSheetState extends State<_RelocationBottomSheet> {
  String _selectedVaultType = 'custom';
  String _selectedLocationPath = '';
  bool _migrateData = true;
  bool _isPicking = false;

  Future<void> _pickFolder() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        setState(() {
          _selectedLocationPath = path;
        });
      }
    } catch (e) {
      debugPrint('Error picking folder: $e');
    } finally {
      setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = DesignColors.text(context);
    final textSecStyle = DesignColors.textSecondary(context);
    final cardBg = DesignColors.surfaceVariant(context);
    final cardBorder = DesignColors.text(context).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 32,
      ),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Relocate Vault Location',
            style: DesignTypography.heading(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textStyle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Move your vaults and notes to a new location. Choose device storage or secure app sandbox storage.',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              color: textSecStyle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: 'custom',
                              activeColor: colorScheme.primary,
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
                          child: Text(
                            'Allows Prism data to be accessed by other apps.',
                            style: DesignTypography.details(context, color: textSecStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                              activeColor: colorScheme.primary,
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
                              Text(
                                '• Your data will not be accessible to other apps.',
                                style: DesignTypography.details(context, color: textSecStyle),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Android will delete your data if you uninstall Prism.',
                                style: DesignTypography.details(context, color: textSecStyle),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conditional Folder Picker
          if (_selectedVaultType == 'custom') ...[
            Text(
              'Select Destination Folder',
              style: DesignTypography.body(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textStyle,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFolder,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedLocationPath.isNotEmpty ? colorScheme.primaryContainer.withValues(alpha: 0.1) : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedLocationPath.isNotEmpty ? colorScheme.primary : cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedLocationPath.isNotEmpty ? Icons.folder_rounded : Icons.folder_open_rounded,
                      color: _selectedLocationPath.isNotEmpty ? colorScheme.primary : textSecStyle,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedLocationPath.isNotEmpty ? _selectedLocationPath : 'Choose a folder...',
                        style: DesignTypography.body(
                          context,
                          fontSize: 13,
                          color: _selectedLocationPath.isNotEmpty ? textStyle : DesignColors.textTertiary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Migration Switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Migrate existing notes to new location',
                        style: DesignTypography.body(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textStyle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Copies all notes and configuration to the new folder.',
                        style: DesignTypography.details(context, color: textSecStyle),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _migrateData,
                  onChanged: (val) => setState(() => _migrateData = val),
                  activeThumbColor: colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Relocation Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_selectedVaultType == 'custom' && _selectedLocationPath.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a destination folder.')),
                );
                return;
              }
              widget.onRelocate(_selectedLocationPath, _selectedVaultType, _migrateData);
            },
            child: Text(
              'Confirm Relocation',
              style: DesignTypography.body(
                context,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
