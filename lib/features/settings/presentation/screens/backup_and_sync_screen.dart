import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../widgets/settings_widgets.dart';

class BackupAndSyncScreen extends StatelessWidget {
  const BackupAndSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Backup & Sync',
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // ── Premium Badge Header ──────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignColors.primary(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_sync_rounded,
                  size: 40,
                  color: DesignColors.primary(context),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Offline-First Security',
                style: DesignTypography.heading(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignColors.text(context),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Prism is designed from the ground up to respect your digital privacy. All notes reside solely on your device. You can opt to configure automated cloud sync or perform physical exports below.',
                  style: DesignTypography.body(
                    context,
                    fontSize: 13,
                    color: DesignColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 32),

            // ── Cloud Services ────────────────────────────────────────────────
            const SettingsSectionHeader(title: 'Cloud Services')
                .animate()
                .fadeIn(delay: 250.ms),
            const ProGateTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Google Drive Sync',
              subtitle: 'Sync your vault to Google Drive',
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // ── Local Utilities ────────────────────────────────────────────────
            const SettingsSectionHeader(title: 'Local Utilities')
                .animate()
                .fadeIn(delay: 350.ms),
            const ProGateTile(
              icon: Icons.file_download_outlined,
              title: 'Export vault',
              subtitle: 'Download all notes as ZIP or PDF',
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),
          ],
        ),
      ),
    );
  }
}
