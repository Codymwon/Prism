import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../notes/data/note_repository.dart';
import '../../../editor/presentation/widgets/audio_player_bottom_sheet.dart';
import 'package:prism/l10n/l10n.dart';

class AttachmentFile {
  final File file;
  final String name;
  final int sizeBytes;
  final DateTime lastModified;
  final bool isReferenced;

  AttachmentFile({
    required this.file,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
    required this.isReferenced,
  });

  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }
}

final attachmentsProvider = FutureProvider<List<AttachmentFile>>((ref) async {
  final vaultPath = await ref.watch(activeVaultPathProvider.future);
  final attachmentsDir = Directory(p.join(vaultPath, 'attachments'));
  if (!await attachmentsDir.exists()) {
    return [];
  }

  // Get all note files to check references
  final noteRepo = ref.read(noteRepositoryProvider);
  final notes = await noteRepo.getAllNotes();
  final filePaths = notes.map((n) => n.filePath).toList();
  
  final referencedNames = await Isolate.run(() {
    final names = <String>{};
    final regex = RegExp(r'attachments/([^)\s]+)');
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          for (final match in regex.allMatches(content)) {
            names.add(match.group(1)!);
          }
        }
      } catch (_) {}
    }
    return names;
  });

  final List<AttachmentFile> result = [];
  try {
    final files = await attachmentsDir.list().toList();
    for (final entity in files) {
      final pathLower = entity.path.toLowerCase();
      final isAudio = pathLower.endsWith('.m4a') || pathLower.endsWith('.mp3');
      final isImage = pathLower.endsWith('.png') ||
                      pathLower.endsWith('.jpg') ||
                      pathLower.endsWith('.jpeg') ||
                      pathLower.endsWith('.gif') ||
                      pathLower.endsWith('.webp') ||
                      pathLower.endsWith('.bmp');
      if (entity is File && (isAudio || isImage)) {
        final name = p.basename(entity.path);
        final stat = await entity.stat();
        result.add(AttachmentFile(
          file: entity,
          name: name,
          sizeBytes: stat.size,
          lastModified: stat.modified,
          isReferenced: referencedNames.contains(name),
        ));
      }
    }
  } catch (_) {}

  // Sort by last modified date (newest first)
  result.sort((a, b) => b.lastModified.compareTo(a.lastModified));
  return result;
});

class AttachmentsScreen extends ConsumerWidget {
  const AttachmentsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attachmentsAsync = ref.watch(attachmentsProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: DesignColors.background(context),
        leading: IconButton(
          icon: const Icon(DesignIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.settings_attachments_title,
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: attachmentsAsync.when(
          data: (attachments) {
            if (attachments.isEmpty) {
              return _buildEmptyState(context);
            }

            final totalSizeBytes = attachments.fold<int>(0, (sum, f) => sum + f.sizeBytes);
            final orphanedCount = attachments.where((f) => !f.isReferenced).length;
            final orphanedSizeBytes = attachments
                .where((f) => !f.isReferenced)
                .fold<int>(0, (sum, f) => sum + f.sizeBytes);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Panel Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: _buildSummaryCard(
                    context,
                    ref,
                    colorScheme,
                    isDark,
                    attachments.length,
                    totalSizeBytes,
                    orphanedCount,
                    orphanedSizeBytes,
                    attachments,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: Text(
                    context.l10n.settings_attachments_section_header,
                    style: DesignTypography.metadata(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DesignColors.textTertiary(context),
                    ),
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAttachmentCard(context, ref, colorScheme, isDark, attachment),
                      ).animate(delay: (30 * index).ms).fadeIn(duration: 250.ms).slideY(begin: 0.05);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading')),
          error: (e, _) => Center(
            child: Text(
              context.l10n.settings_attachments_error(e.toString()),
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isDark,
    int totalCount,
    int totalSize,
    int orphanedCount,
    int orphanedSize,
    List<AttachmentFile> attachments,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.settings_attachments_storage_consumed,
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 11,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatBytes(totalSize),
                      style: DesignTypography.display(
                        context,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: DesignColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.settings_attachments_count_saved(totalCount),
                      style: DesignTypography.details(context),
                    ),
                  ],
                ),
              ),
              if (orphanedCount > 0)
                TactileWrapper(
                  style: TactileFeedbackStyle.highImpact,
                  onTap: () => _confirmCleanUp(context, ref, attachments),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cleaning_services_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.settings_attachments_clean_orphaned,
                          style: DesignTypography.body(
                            context,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (orphanedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.settings_attachments_orphaned_warning(orphanedCount, _formatBytes(orphanedSize)),
                      style: DesignTypography.details(
                        context,
                        color: isDark ? Colors.orange[200] : Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isDark,
    AttachmentFile attachment,
  ) {
    final dateStr = DateFormat('MMMM d, y • h:mm a').format(attachment.lastModified);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: Row(
        children: [
          // Icon represent micro recording or image thumbnail
          attachment.isImage
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DesignColors.border(context), width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      attachment.file,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image_outlined,
                          size: 18,
                          color: DesignColors.textTertiary(context),
                        );
                      },
                    ),
                  ),
                )
              : Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 18,
                    color: DesignColors.textSecondary(context),
                  ),
                ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: DesignTypography.body(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr • ${_formatBytes(attachment.sizeBytes)}',
                  style: DesignTypography.details(context),
                ),
                const SizedBox(height: 4),
                // Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: attachment.isReferenced
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            attachment.isReferenced ? Icons.link : Icons.link_off,
                            size: 10,
                            color: attachment.isReferenced ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            attachment.isReferenced ? 'Linked' : 'Orphaned',
                            style: DesignTypography.metadata(
                              context,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: attachment.isReferenced ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!attachment.isImage)
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => AudioPlayerBottomSheet(
                        filePath: attachment.file.path,
                        fileName: attachment.name,
                      ),
                    );
                  },
                  tooltip: context.l10n.settings_attachments_play_recording_tooltip,
                  color: colorScheme.primary,
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () => _confirmDelete(context, ref, attachment.file),
                tooltip: 'Delete File',
                color: Colors.redAccent.withValues(alpha: 0.8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignColors.surfaceVariant(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.audio_file_outlined,
                size: 40,
                color: DesignColors.textTertiary(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.settings_attachments_empty_title,
              style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.settings_attachments_empty_desc,
              style: DesignTypography.details(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignColors.background(context),
        title: Text(
          'Delete Attachment',
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.l10n.settings_attachments_delete_confirm_desc,
          style: DesignTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: DesignTypography.body(context)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (await file.exists()) {
                  await file.delete();
                }
                ref.invalidate(attachmentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.settings_attachments_delete_success)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.settings_attachments_delete_error(e.toString()))),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: DesignTypography.body(context, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCleanUp(BuildContext context, WidgetRef ref, List<AttachmentFile> attachments) {
    final orphaned = attachments.where((f) => !f.isReferenced).toList();
    final count = orphaned.length;
    final totalSizeStr = _formatBytes(orphaned.fold<int>(0, (sum, f) => sum + f.sizeBytes));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignColors.background(context),
        title: Text(
          context.l10n.settings_attachments_purge_orphaned_title,
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.l10n.settings_attachments_purge_orphaned_desc(count, totalSizeStr),
          style: DesignTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: DesignTypography.body(context)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                int deletedCount = 0;
                for (final item in orphaned) {
                  if (await item.file.exists()) {
                    await item.file.delete();
                    deletedCount++;
                  }
                }
                ref.invalidate(attachmentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.settings_attachments_purge_success(deletedCount))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.settings_attachments_purge_error(e.toString()))),
                  );
                }
              }
            },
            child: Text(
              context.l10n.settings_attachments_purge_all_button,
              style: DesignTypography.body(context, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}