import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // ── Privacy Policy Content Sections ────────────────────────────────
                  _buildSectionHeader(context, '1. DATA COLLECTION & STORAGE'),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.offline_bolt_rounded,
                    title: 'Offline Storage',
                    description:
                        'Your markdown files, journal entries, and configuration settings are stored locally on your device vault. We do not operate server databases, meaning we cannot read, sync, or sell your personal writing.',
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
                  const SizedBox(height: 12),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'No Telemetry & Analytics',
                    description:
                        'Prism does not run tracking SDKs, telemetry frameworks, or diagnostic reporting that sends data back to developers or advertising networks. Your in-app behavior is yours alone.',
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),

                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '2. DEVICE PERMISSIONS'),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.mic_none_rounded,
                    title: 'Microphone Access',
                    description:
                        'Used exclusively when you activate the voice dictation toolbar button to record audio attachments or perform speech-to-text. Audio files are saved inside your vault and processed locally.',
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
                  const SizedBox(height: 12),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.folder_open_outlined,
                    title: 'Storage / Filesystem Access',
                    description:
                        'Required to let you select a local folder directory for your vaults, enabling Prism to read, write, and manage your standard markdown files.',
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),

                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '3. OPTIONAL CLOUD INTEGRATION'),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.cloud_queue_rounded,
                    title: 'Google Drive Sync',
                    description:
                        'If you choose to configure the Google Drive integration, connection is established directly between your device and Google servers. We never intercept, store, or have access to your Google credentials or synced notes.',
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),

                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '4. COMPLIANCE WITH LAWS'),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.gavel_rounded,
                    title: 'GDPR, CCPA & Privacy Rights',
                    description:
                        'Under global privacy frameworks like GDPR (EU) and CCPA/CPRA (California), users maintain the absolute right to view and purge their data. Because your notes are standard markdown text files stored locally, you hold complete access, modification, and deletion capability at all times. Simply delete your vault folders to purge your data.',
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),

                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '5. CONTACT & UPDATES'),
                  _buildPrivacyCard(
                    context,
                    icon: Icons.mail_outline_rounded,
                    title: 'Privacy Queries',
                    description:
                        'We may update this policy occasionally as new features roll out. For privacy concerns, code transparency audits, or feedback, email us at privacy@prismnotes.com.',
                  ).animate().fadeIn(delay: 550.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),

                  const SizedBox(height: 48),
                ],
              ),
            ),
            
            // ── Public Link Footer Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: DesignColors.surface(context),
                border: Border(
                  top: BorderSide(color: DesignColors.border(context)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Store Listing URL',
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesignColors.textTertiary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'https://prismnotes.com/privacy',
                      style: DesignTypography.body(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignColors.primary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TactileWrapper(
                      style: TactileFeedbackStyle.highImpact,
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: 'https://prismnotes.com/privacy'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy link copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: DesignColors.primary(context),
                          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Copy Privacy Link',
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: DesignTypography.metadata(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: DesignColors.textTertiary(context),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: DesignColors.primary(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTypography.body(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignColors.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: DesignTypography.body(
                    context,
                    fontSize: 12,
                    height: 1.5,
                    color: DesignColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
