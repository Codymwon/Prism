import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/services/vault_export_service.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../core/config/app_config.dart';
import '../providers/export_provider.dart';
import 'package:prism/l10n/l10n.dart';

/// Full-screen Vault Export page.
class VaultExportScreen extends ConsumerWidget {
  const VaultExportScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.settings_export_bottom_sheet_title,
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Intro Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignColors.primary(context).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DesignColors.primary(context).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: DesignColors.primary(context),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local Backup & Portability',
                            style: DesignTypography.body(
                              context,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your data is entirely yours. Export your vault in open formats at any time for maximum backup security and portability.',
                            style: DesignTypography.details(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                context.l10n.settings_export_bottom_sheet_choose_format,
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),

              // Export state switches
              exportState.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(semanticsLabel: 'Exporting'),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.settings_export_bottom_sheet_exporting,
                          style: DesignTypography.body(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                error: (err, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ErrorBanner(message: _errorMessage(err)),
                    const SizedBox(height: 16),
                    _buildFormatList(context, ref, isPro, primaryColor),
                  ],
                ),
                data: (result) {
                  if (result != null) {
                    return _SuccessBlock(result: result);
                  }
                  return _buildFormatList(context, ref, isPro, primaryColor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatList(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
    Color primaryColor,
  ) {
    final formats = AppConfig.enableSubscriptions
        ? _formats
        : _formats.where((f) => !f.requiresPro).toList();

    return Column(
      children: formats.map((f) {
        final locked = AppConfig.enableSubscriptions && f.requiresPro && !isPro;
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

  String _errorMessage(Object err) {
    if (err is VaultExportFailure) return err.message;
    return err.toString();
  }
}

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: primaryColor),
            ),
            const SizedBox(width: 14),
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
                          fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: DesignTypography.details(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              size: 20,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 10),
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.settings_export_bottom_sheet_complete,
                          style: DesignTypography.body(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.settings_export_bottom_sheet_notes_count(
                            result.noteCount,
                            _formatBytes(result.bytes),
                          ),
                          style: DesignTypography.details(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.folder_outlined, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      result.savedPath,
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.primary(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.settings_export_bottom_sheet_done_button),
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
