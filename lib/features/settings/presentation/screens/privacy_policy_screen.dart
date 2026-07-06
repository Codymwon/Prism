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
                    title: '1. WHAT WE COLLECT',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Your Notes & Files',
                        description:
                            'Your markdown files, journal entries, and configuration settings are stored exclusively on your device. We do not operate server databases — we cannot read, sync, or sell your personal writing.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Anonymous Usage Telemetry (opt-out)',
                        description:
                            'If you consent during onboarding, Prism uses Firebase Analytics to collect anonymous, aggregated app usage events (e.g. feature taps, editor mode switches). No note content, search queries, file paths, or personal identifiers are ever included. You can disable this at any time in Settings → Gestures & Feedback.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Crash Reports (opt-out)',
                        description:
                            'If you consent, Firebase Crashlytics collects anonymous crash logs and error stack traces to help us fix bugs. These contain no note content or personal data. Crash reports are retained for 90 days. You can disable this alongside usage telemetry in Settings → Gestures & Feedback.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Subscription Status',
                        description:
                            'Prism uses RevenueCat to verify your Prism Pro subscription status. RevenueCat receives a pseudonymous user identifier and purchase receipts from the app store. No personal information is shared. RevenueCat\'s privacy policy is available at revenuecat.com/privacy.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Font Downloads',
                        description:
                            'On first launch, Prism downloads font files from Google Fonts (fonts.googleapis.com). These are cached locally on your device after the initial download — no personal data is transmitted, and the app functions fully offline thereafter.',
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
                            'Under global privacy frameworks like GDPR (EU) and CCPA/CPRA (California), you have the right to access and delete your data. Because your notes are standard markdown files stored locally, you hold complete access and deletion capability at all times — simply delete your vault folders to purge your data.\n\nFor anonymous telemetry data held by Firebase, you may request deletion by contacting us. We will process requests within 30 days.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Data Retention',
                        description:
                            'Anonymous crash reports are retained for 90 days in Firebase. Anonymous usage analytics are retained for 14 months per Google\'s standard Analytics retention policy. Support emails are retained until your issue is resolved. Your local notes and files are yours — we never hold them.',
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
                            'We may update this policy occasionally as new features roll out. For privacy concerns, data deletion requests, or feedback, email us at Prismprivacy@smallgiantstudio.com.',
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
                      'https://smallgiantstudio.com/prism/privacy',
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
                        Clipboard.setData(const ClipboardData(text: 'https://smallgiantstudio.com/prism/privacy'));
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
