import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/prism_toast.dart';
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
                        title: 'Anonymous Usage Telemetry (opt-in)',
                        description:
                            'If you explicitly opt-in during onboarding, Prism uses Firebase Analytics to collect anonymous, aggregated app usage events (e.g. feature taps, editor mode switches). No note content, search queries, file paths, or personal identifiers are ever included. You can disable or enable this at any time in Settings → Gestures & Feedback.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Crash Reports (opt-in)',
                        description:
                            'If you explicitly opt-in, Firebase Crashlytics collects anonymous crash logs and error stack traces to help us fix bugs. These contain no note content or personal data. Crash reports are retained for 90 days. You can disable or enable this alongside usage telemetry in Settings → Gestures & Feedback.',
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
                            'If you choose to configure the Google Drive integration, connection is established directly between your device and Google servers. We never intercept, store, or have access to your Google credentials or synced notes.',
                      ),
                      _buildLimitedUseCallout(context),
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
                        title: 'GDPR, CCPA & Global Privacy Rights (including DPDPA India)',
                        description:
                            'Under global privacy frameworks like GDPR (EU), CCPA/CPRA (California), and the Digital Personal Data Protection Act (India), you have the right to access and delete your data. Because your notes are standard markdown files stored locally, you hold complete access and deletion capability at all times.\n\nYou can perform a full, irreversible data purge and factory reset at any time in the app via Settings → Danger Zone → "Delete All Data & Reset".\n\nIf you have uninstalled the app or wish to submit an off-device deletion request for any associated identifiers, visit our online Data Deletion Portal or contact us at privacy@smallgiantstudio.com. We process all requests within 30 days.',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () async {
                            final url = Uri.parse('https://smallgiantstudio.com/prism/delete-account');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Text(
                            'Online Data & Account Deletion Request Portal',
                            style: TextStyle(
                              color: DesignColors.primary(context),
                              decoration: TextDecoration.underline,
                              fontSize: 12,
                            ),
                          ),
                        ),
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
                    title: '5. CHILDREN\'S PRIVACY (COPPA & GDPR ART. 8)',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Age Limitations & Child Data Protection',
                        description:
                            'Prism is an offline-first personal workspace utility not directed to or intended for children under thirteen (13) years of age (or under sixteen (16) years of age in the European Economic Area and California). We do not knowingly solicit, collect, or process personal data from children under these age thresholds.\n\nIf we discover that personal data of a minor has been collected without verified parental consent, we will take immediate measures to permanently delete such information from our records and anonymous telemetry logs. If you are a parent or legal guardian and believe that your child has provided us with personal information, please contact our Data Controller at privacy@smallgiantstudio.com for immediate resolution.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '6. DATA CONTROLLER & CONTACT',
                    items: [
                      _buildPrivacyItem(
                        context,
                        title: 'Data Controller Identity & Address',
                        description:
                            'Small Giant Studio (an independent software project operated by its developer)\nCountry of Operation: India\n\nContact Email: privacy@smallgiantstudio.com (or legal@smallgiantstudio.com)',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Grievance Officer (India IT Rules 2021)',
                        description:
                            'In accordance with the Information Technology Act, 2000 and the Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021, the designated Grievance Officer for Prism is:\n\nDesignation: Grievance Officer, Small Giant Studio\nEmail: privacy@smallgiantstudio.com\n\nWe acknowledge grievances within 48 hours and resolve all issues within fifteen (15) days of receipt.',
                      ),
                      _buildPrivacyItem(
                        context,
                        title: 'Privacy Inquiries & Deletion Requests',
                        description:
                            'For questions regarding this Privacy Policy, CCPA/GDPR/DPDPA data subject access requests (DSAR), deletion inquiries, or our Google Limited Use commitments, email us at privacy@smallgiantstudio.com.',
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
                        PrismToast.show(
                          context,
                          'Privacy Policy link copied to clipboard!',
                          icon: Icons.copy_rounded,
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

  Widget _buildLimitedUseCallout(BuildContext context) {
    final primaryColor = DesignColors.primary(context);
    final borderColor = DesignColors.border(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'GOOGLE API SERVICES LIMITED USE COMPLIANCE',
              style: DesignTypography.metadata(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ).copyWith(letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Google Drive Data Safeguards',
            style: DesignTypography.body(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),
          Text(
            'Prism\'s use and transfer of information received from Google APIs to any other app will adhere to Google API Services User Data Policy, including the Limited Use requirements:\n\n'
            '• Sole Purpose of Synchronization: Access to Google Drive is requested and utilized exclusively to read, write, and synchronize your personal markdown vaults and associated media attachments across your authorized devices.\n\n'
            '• No Advertising, Retargeting, or Profiling: Data accessed from Google Drive is never used, transferred, or disclosed for serving advertisements, retargeting, personalized marketing, or building commercial user profiles.\n\n'
            '• No AI/ML Model Training: Your note content, file metadata, and Google Drive data are never used or transferred to train, retrain, fine-tune, or improve generalized artificial intelligence or machine learning (AI/ML) models.\n\n'
            '• No Human Inspection: No human employees, contractors, or agents of Small Giant Studio will read your note content or Google Drive files without first obtaining your explicit affirmative permission (e.g., during troubleshooting at your direct request), or unless necessary for security or legal compliance.',
            style: DesignTypography.details(
              context,
              fontSize: 12,
              color: DesignColors.text(context),
            ).copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}
