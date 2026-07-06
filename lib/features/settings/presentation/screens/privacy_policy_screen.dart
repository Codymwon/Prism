import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  _buildSection(
                    context,
                    title: '1. DATA COLLECTION & STORAGE',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Offline Storage',
                        description:
                            'Your markdown files, journal entries, and configuration settings are stored locally on your device vault. We do not operate server databases, meaning we cannot read, sync, or sell your personal writing.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'No Telemetry & Analytics',
                        description:
                            'Prism does not run tracking SDKs, telemetry frameworks, or diagnostic reporting that sends data back to developers or advertising networks. Your in-app behavior is yours alone.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '2. DEVICE PERMISSIONS',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Microphone Access',
                        description:
                            'Used exclusively when you activate the voice dictation toolbar button to record audio attachments or perform speech-to-text. Audio files are saved inside your vault and processed locally.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Storage / Filesystem Access',
                        description:
                            'Required to let you select a local folder directory for your vaults, enabling Prism to read, write, and manage your standard markdown files.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '3. OPTIONAL CLOUD INTEGRATION',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Google Drive Sync',
                        description:
                            'If you choose to configure the Google Drive integration, connection is established directly between your device and Google servers. We never intercept, store, or have access to your Google credentials or synced notes.\n\nPrism\'s use and transfer of information received from Google APIs to any other app will adhere to Google API Services User Data Policy, including the Limited Use requirements.',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () async {
                            final url = Uri.parse('https://developers.google.com/terms/api-services-user-data-policy');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Text(
                            'View Google API Services User Data Policy',
                            style: TextStyle(
                              color: DesignColors.primary(context),
                              decoration: TextDecoration.underline,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '4. COMPLIANCE WITH LAWS',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'GDPR, CCPA & Privacy Rights',
                        description:
                            'Under global privacy frameworks like GDPR (EU) and CCPA/CPRA (California), users maintain the absolute right to view and purge their data. Because your notes are standard markdown text files stored locally, you hold complete access, modification, and deletion capability at all times. Simply delete your vault folders to purge your data.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '5. CONTACT & UPDATES',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Privacy Queries',
                        description:
                            'We may update this policy occasionally as new features roll out. For privacy concerns, code transparency audits, or feedback, email us at privacy@prismnotes.com.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            
            // ── Public Link Footer Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: DesignColors.background(context),
                border: Border(
                  top: BorderSide(color: DesignColors.border(context), width: 0.5),
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

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTypography.metadata(
            context,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: DesignColors.primary(context),
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildPrivacyItem(BuildContext context, {required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DesignTypography.body(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
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
    );
  }
}
