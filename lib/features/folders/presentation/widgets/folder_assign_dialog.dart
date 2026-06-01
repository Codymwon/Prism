import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/folder_repository.dart';
import '../../../notes/data/note_repository.dart';



class FolderAssignDialog extends ConsumerWidget {
  final String noteId;

  const FolderAssignDialog({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final foldersAsync = ref.watch(foldersProvider);
    final assignedFoldersAsync = ref.watch(foldersForNoteProvider(noteId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262628) : const Color(0xFFFDFBFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Text(
              'Organize Note',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Select one or more folders to categorize this note. Visual folders are purely database-mapped.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Folders checklist
            Flexible(
              child: foldersAsync.when(
                data: (allFolders) {
                  if (allFolders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No virtual folders created yet. Add them from the sidebar drawer first!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return assignedFoldersAsync.when(
                    data: (assignedFolders) {
                      final assignedIds = assignedFolders.map((f) => f.id).toSet();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: allFolders.length,
                        itemBuilder: (context, index) {
                          final folder = allFolders[index];
                          final isAssigned = assignedIds.contains(folder.id);
                          
                          final hexColor = folder.colorHex.replaceAll('#', '');
                          final colorVal = int.tryParse('FF$hexColor', radix: 16) ?? 0xFF7C6FF7;
                          final folderColor = Color(colorVal);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3EFE8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE6DFD5),
                                width: 0.5,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: folderColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    folder.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              value: isAssigned,
                              activeColor: folderColor,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onChanged: (bool? checked) async {
                                final repo = ref.read(folderRepositoryProvider);
                                if (checked == true) {
                                  await repo.addNoteToFolder(noteId, folder.id);
                                } else {
                                  await repo.removeNoteFromFolder(noteId, folder.id);
                                }
                                ref.invalidate(foldersForNoteProvider(noteId));
                                ref.invalidate(foldersProvider);
                                // Also invalidate notesProvider in case list is filtered
                                ref.invalidate(notesProvider);
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ),
            const SizedBox(height: 16),

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
