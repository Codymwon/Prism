import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';
import 'hsv_color_picker.dart';

class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return Drawer(
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vault Folders',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.create_new_folder_outlined,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => showAddFolderSheet(context, ref),
                    tooltip: 'Add Folder',
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, indent: 20, endIndent: 20),
            
            // List of Folders
            Expanded(
              child: foldersAsync.when(
                data: (folders) => _buildFolderList(
                  context,
                  ref,
                  folders,
                  selectedFolderId,
                  isDark,
                  colorScheme,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error loading folders: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: -0.1, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildFolderList(
    BuildContext context,
    WidgetRef ref,
    List<VirtualFolder> folders,
    String? selectedFolderId,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // "All Notes" (system folder)
        _buildFolderTile(
          context: context,
          name: 'All Notes',
          color: colorScheme.primary,
          icon: Icons.notes_rounded,
          isSelected: selectedFolderId == null,
          noteCount: null, // NoteRepository has notes list count
          isDark: isDark,
          onTap: () {
            ref.read(selectedFolderIdProvider.notifier).state = null;
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 6),
          child: Text(
            'CATEGORIES',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
            ),
          ),
        ),

        if (folders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: Text(
              'No virtual folders created yet. Tap the top icon to organize your files.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
                height: 1.5,
              ),
            ),
          )
        else
          ...folders.map((folder) {
            final isSelected = selectedFolderId == folder.id;
            final folderColor = folder.colorHex.toColor();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildFolderTile(
                context: context,
                name: folder.name,
                color: folderColor,
                icon: Icons.folder_rounded,
                isSelected: isSelected,
                noteCount: folder.noteCount,
                isDark: isDark,
                onTap: () {
                  ref.read(selectedFolderIdProvider.notifier).state = folder.id;
                  Navigator.pop(context);
                },
                onLongPress: () => showFolderOptions(context, ref, folder),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFolderTile({
    required BuildContext context,
    required String name,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required int? noteCount,
    required bool isDark,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final activeTextColor = isDark ? Colors.white : Colors.black;
    final inactiveTextColor = isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary;

    return TactileWrapper(
      onTap: onTap,
      onLongPress: onLongPress,
      style: onLongPress != null ? TactileFeedbackStyle.longPressLift : TactileFeedbackStyle.standard,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Folder Dot/Icon
              icon == Icons.notes_rounded
                  ? Icon(icon, size: 18, color: color)
                  : Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: 16),
              
              // Name
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),
              
              // Note Count Badge
              if (noteCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.25 : 0.2)
                        : (isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$noteCount',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : inactiveTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddFolderSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    Color selectedColor = const Color(0xFF7C6FF7); // default Bear terracottaish color

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF262628)
          : const Color(0xFFFDFBFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (stateContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Folder',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Name Input
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Folder name',
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Color Display Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Folder Color',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.color_lens_outlined, size: 16),
                      label: Text(
                        'Change',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final pickedColor = await showDialog<Color>(
                          context: sheetContext,
                          builder: (dialogCtx) => HsvColorPickerDialog(
                            initialColor: selectedColor,
                          ),
                        );
                        if (pickedColor != null) {
                          setSheetState(() {
                            selectedColor = pickedColor;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final hex = '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      await ref.read(folderRepositoryProvider).createFolder(
                            name,
                            colorHex: hex,
                          );
                      ref.invalidate(foldersProvider);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Create Folder',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showFolderOptions(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            
            // Header
            ListTile(
              title: Text(
                'Folder: ${folder.name}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Edit
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('Edit details', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(ctx);
                showEditFolderSheet(context, ref, folder);
              },
            ),

            // Delete
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Delete folder', style: GoogleFonts.inter(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('Delete Folder?'),
                    content: Text(
                      'This will delete the "${folder.name}" category organization. None of the physical markdown files will be deleted.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // If deleted folder was active, clear filter
                  if (ref.read(selectedFolderIdProvider) == folder.id) {
                    ref.read(selectedFolderIdProvider.notifier).state = null;
                  }
                  await ref.read(folderRepositoryProvider).deleteFolder(folder.id);
                  ref.invalidate(foldersProvider);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void showEditFolderSheet(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    final nameController = TextEditingController(text: folder.name);
    Color selectedColor = folder.colorHex.toColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF262628)
          : const Color(0xFFFDFBFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (stateContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Folder',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Name Input
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Folder name',
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Color Display Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Folder Color',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.color_lens_outlined, size: 16),
                      label: Text(
                        'Change',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final pickedColor = await showDialog<Color>(
                          context: sheetContext,
                          builder: (dialogCtx) => HsvColorPickerDialog(
                            initialColor: selectedColor,
                          ),
                        );
                        if (pickedColor != null) {
                          setSheetState(() {
                            selectedColor = pickedColor;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final hex = '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      await ref.read(folderRepositoryProvider).updateFolder(
                            folder.id,
                            name,
                            hex,
                            folder.icon,
                          );
                      ref.invalidate(foldersProvider);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
