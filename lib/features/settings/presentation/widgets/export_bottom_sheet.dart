import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/services/vault_export_service.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/export_provider.dart';

/// Export Vault bottom sheet.
///
/// Architecture (V5): ConsumerWidget (stateless) — all state lives in
/// [ExportSheetController]. No local TextEditingController or AnimationController.
///
/// Architecture (V6): This widget only DISPLAYS which options are Pro-locked.
/// Enforcement (Pro gate) lives entirely in [ExportSheetController.run()].
class ExportBottomSheet extends ConsumerWidget {
  const ExportBottomSheet({super.key});

  // ── Format metadata ──────────────────────────────────────────────────────────

  static const _formats = [
    (
      format: ExportFormat.json,
      icon: Icons.data_object_rounded,
      label: 'JSON export',
      description: 'All notes, tags, backlinks and folder names in a structured JSON file',
      requiresPro: false,
    ),
    (
      format: ExportFormat.zipArchive,
      icon: Icons.folder_zip_outlined,
      label: 'ZIP archive',
      description: 'All markdown notes and attachments in a single ZIP file',
      requiresPro: true,
    ),
    (
      format: ExportFormat.pdfCompiled,
      icon: Icons.picture_as_pdf_outlined,
      label: 'Single PDF',
      description: 'All notes compiled into one paginated PDF document',
      requiresPro: true,
    ),
    (
      format: ExportFormat.pdfZipped,
      icon: Icons.folder_open_outlined,
      label: 'PDFs in ZIP',
      description: 'Each note rendered as its own PDF, bundled in a ZIP',
      requiresPro: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportSheetControllerProvider);
    final isPro = ref.watch(isProProvider);
    final primaryColor = DesignColors.primary(context);

    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: DesignColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Export Vault',
                style: DesignTypography.heading(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a format to export your notes',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              color: DesignColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),

          // ── Body switches on state ───────────────────────────────────────────
          exportState.when(
            // ── Loading state: indeterminate spinner ────────────────────────
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting…', textAlign: TextAlign.center),
                ],
              ),
            ),

            // ── Error state: red banner ──────────────────────────────────────
            error: (err, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ErrorBanner(message: _errorMessage(err)),
                const SizedBox(height: 20),
                _buildFormatList(context, ref, isPro, primaryColor),
                const SizedBox(height: 8),
              ],
            ),

            // ── Data state: null = idle, non-null = success ──────────────────
            data: (result) {
              if (result != null) {
                // Success block
                return _SuccessBlock(result: result);
              }
              // Idle: show format selector
              return _buildFormatList(context, ref, isPro, primaryColor);
            },
          ),
        ],
      ),
    );
  }

  // ── Format list ─────────────────────────────────────────────────────────────

  Widget _buildFormatList(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
    Color primaryColor,
  ) {
    return Column(
      children: _formats.map((f) {
        final locked = f.requiresPro && !isPro;
        return _FormatRow(
          icon: f.icon,
          label: f.label,
          description: f.description,
          locked: locked,
          primaryColor: primaryColor,
          onTap: () => ref.read(exportSheetControllerProvider.notifier).run(
                f.format,
                context: context,
              ),
        );
      }).toList(),
    );
  }

  // ── Error message extraction ─────────────────────────────────────────────────

  String _errorMessage(Object err) {
    if (err is VaultExportFailure) return err.message;
    return err.toString();
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FormatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool locked;
  final Color primaryColor;
  final VoidCallback onTap;

  const _FormatRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.locked,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignColors.border(context)),
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: primaryColor),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: DesignTypography.body(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: DesignTypography.metadata(
                              context,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: DesignTypography.details(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Trailing icon
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: DesignTypography.body(
                context,
                fontSize: 13,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBlock extends StatelessWidget {
  final VaultExportResult result;
  const _SuccessBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Complete',
                    style: DesignTypography.body(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.noteCount} notes · ${_formatBytes(result.bytes)}',
                    style: DesignTypography.details(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.savedPath,
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 11,
                    color: Colors.green.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.primary(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
