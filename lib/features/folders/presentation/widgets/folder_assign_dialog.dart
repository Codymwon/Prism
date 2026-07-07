import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../data/folder_repository.dart';
import '../../presentation/providers/folders_providers.dart';
import 'package:prism/l10n/l10n.dart';

class FolderAssignDialog extends ConsumerStatefulWidget {
  final String noteId;

  const FolderAssignDialog({super.key, required this.noteId});

  @override
  ConsumerState<FolderAssignDialog> createState() => _FolderAssignDialogState();
}

class _FolderAssignDialogState extends ConsumerState<FolderAssignDialog> {
  Set<String>? _optimisticAssignedIds;

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final assignedFoldersAsync = ref.watch(foldersForNoteProvider(widget.noteId));

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
              context.l10n.folders_assign_dialog_title,
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
              child: Builder(
                builder: (context) {
                  // Handle error states
                  if (foldersAsync.hasError && foldersAsync.valueOrNull == null) {
                    return Center(
                      child: Text(
                        context.l10n.folders_assign_dialog_error_folders(foldersAsync.error.toString()),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }
                  if (assignedFoldersAsync.hasError && assignedFoldersAsync.valueOrNull == null) {
                    return Center(
                      child: Text(
                        context.l10n.folders_assign_dialog_error_assignments(assignedFoldersAsync.error.toString()),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }

                  final allFolders = foldersAsync.valueOrNull;
                  final assignedFolders = assignedFoldersAsync.valueOrNull;

                  // Update/initialize optimistic state
                  if (assignedFolders != null) {
                    if (_optimisticAssignedIds == null || !assignedFoldersAsync.isLoading) {
                      _optimisticAssignedIds = assignedFolders.map((f) => f.id).toSet();
                    }
                  }

                  // If still loading initially (no cached data), show spinner
                  if (allFolders == null || assignedFolders == null || _optimisticAssignedIds == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(semanticsLabel: 'Loading'),
                      ),
                    );
                  }

                  if (allFolders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        context.l10n.folders_assign_dialog_empty,
                        style: DesignTypography.details(
                          context,
                          fontSize: 13,
                          color: DesignColors.textTertiary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: allFolders.length,
                    itemBuilder: (context, index) {
                      final folder = allFolders[index];
                      final isAssigned = _optimisticAssignedIds!.contains(folder.id);
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
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _optimisticAssignedIds!.add(folder.id);
                              } else {
                                _optimisticAssignedIds!.remove(folder.id);
                              }
                            });

                            // Perform DB update in background asynchronously
                            final repo = ref.read(folderRepositoryProvider);
                            if (checked == true) {
                              repo.addNoteToFolder(widget.noteId, folder.id);
                            } else {
                              repo.removeNoteFromFolder(widget.noteId, folder.id);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
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