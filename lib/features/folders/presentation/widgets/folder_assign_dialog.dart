import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../data/folder_repository.dart';
import '../../presentation/providers/folders_providers.dart';

class FolderAssignDialog extends ConsumerWidget {
  final String noteId;

  const FolderAssignDialog({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final assignedFoldersAsync = ref.watch(foldersForNoteProvider(noteId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: DesignColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DesignSheetDragHandle(),
            Text(
              'Organize Note',
              style: DesignTypography.heading(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Select one or more folders to categorize this note. Visual folders are purely database-mapped.',
              style: DesignTypography.details(
                context,
                color: DesignColors.textSecondary(context),
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
                        style: DesignTypography.details(
                          context,
                          fontSize: 13,
                          color: DesignColors.textTertiary(context),
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
                          final folderColor = folder.colorHex.toColor();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: DesignColors.surface(context),
                              borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                              border: Border.all(
                                color: DesignColors.border(context),
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
                                    style: DesignTypography.body(
                                      context,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              value: isAssigned,
                              activeColor: folderColor,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                              ),
                              onChanged: (bool? checked) async {
                                final repo = ref.read(folderRepositoryProvider);
                                if (checked == true) {
                                  await repo.addNoteToFolder(noteId, folder.id);
                                } else {
                                  await repo.removeNoteFromFolder(noteId, folder.id);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ),
            const SizedBox(height: 16),

            // Close button
            DesignSecondaryButton(
              label: 'Done',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
