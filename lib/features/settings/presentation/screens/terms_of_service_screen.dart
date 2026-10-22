import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/prism_toast.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const String publicTermsUrl = 'https://smallgiantstudio.com/prism/terms';
  static const String contactEmail = 'legal@smallgiantstudio.com';

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
          'Terms of Service',
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
                  Text(
                    'Last Updated: September 29, 2026',
                    style: DesignTypography.metadata(
                      context,
                      color: DesignColors.textTertiary(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 1 ───────────────────────────────────────────────
                  _buildSection(
                    context,
                    title: '1. ACCEPTANCE OF TERMS & ELIGIBILITY',
                    items: [
                      _buildTermsItem(
                        context,
                        title: 'Contractual Agreement',
                        description:
                            'These Terms of Service ("Terms") constitute a legally binding agreement between you and Small Giant Studio ("Company", "we", "us", or "our") concerning your access to and use of the Prism mobile application and associated software utilities (collectively, "Prism"). By downloading, installing, accessing, or using Prism, you agree to be bound by these Terms and our Privacy Policy. If you do not agree, do not install or use Prism.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'Age Eligibility',
                        description:
                            'Prism is intended solely for users who are at least thirteen (13) years of age (or sixteen (16) years of age in the European Economic Area). If you are under the required age, you may not use Prism.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Section 2: Conspicuous UCC Disclaimer ───────────────────
                  _buildConspicuousCard(
                    context,
                    badgeText: 'UCC § 2-316 STATUTORY DISCLAIMER',
                    title: '2. DISCLAIMER OF WARRANTIES ("AS IS")',
                    content:
                        'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, PRISM IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, QUIET ENJOYMENT, ACCURACY, SYSTEM INTEGRATION, OR NON-INFRINGEMENT.\n\n'
                        'SMALL GIANT STUDIO DOES NOT WARRANT THAT PRISM WILL BE UNINTERRUPTED, TIMELY, SECURE, ERROR-FREE, OR FREE OF BUGS, MALWARE, OR SYSTEM DEFECTS. WE MAKE NO WARRANTY THAT FILE SYSTEM READ OR WRITE OPERATIONS, LOCAL SQLITE INDEXING, METADATA COMPILATION, AUTOMATED BACKLINK RESOLUTION, SEARCH INDEXING, OR SYNCHRONIZATION VIA GOOGLE DRIVE OR ANY THIRD-PARTY CLOUD PROVIDER WILL FUNCTION WITHOUT CONFLICTS, FILE CORRUPTION, DATA OVERWRITE, LOSS OF NOTES, OR PERMANENT VAULT DELETION. YOU ASSUME ALL RISK ARISING OUT OF THE SELECTION, INSTALLATION, AND OPERATION OF PRISM.',
                  ),
                  const SizedBox(height: 24),

                  // ── Section 3: Conspicuous Limitation of Liability ──────────
                  _buildConspicuousCard(
                    context,
                    badgeText: 'CRITICAL LIABILITY LIMITATION & BACKUP OBLIGATION',
                    title: '3. LIMITATION OF LIABILITY & USER BACKUP DUTY',
                    content:
                        'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL SMALL GIANT STUDIO, ITS DEVELOPERS, AFFILIATES, CONTRACTORS, OR AGENTS BE LIABLE TO YOU OR ANY THIRD PARTY FOR ANY INDIRECT, CONSEQUENTIAL, EXEMPLARY, INCIDENTAL, SPECIAL, OR PUNITIVE DAMAGES WHATSOEVER, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOSS OF PROFITS, LOSS OF REVENUE, LOSS OF GOODWILL, BUSINESS INTERRUPTION, LOSS OF DATA, CORRUPTION OR ALTERATION OF MARKDOWN NOTES, ACCIDENTAL VAULT DELETION, OR THE COST OF RECOVERING OR RECONSTRUCTING LOST FILES, ARISING OUT OF OR IN CONNECTION WITH YOUR USE OR INABILITY TO USE PRISM, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.\n\n'
                        'AGGREGATE LIABILITY CAP: IN NO EVENT SHALL THE TOTAL AGGREGATE LIABILITY OF SMALL GIANT STUDIO ARISING OUT OF OR RELATING TO THESE TERMS OR YOUR USE OF PRISM EXCEED THE GREATER OF FIFTY UNITED STATES DOLLARS (\$50.00 USD) OR THE TOTAL FEES ACTUALLY PAID BY YOU TO PRISM FOR SUBSCRIPTION SERVICES IN THE TWELVE (12) MONTHS IMMEDIATELY PRECEDING THE OCCURRENCE GIVING RISE TO LIABILITY.\n\n'
                        'MANDATORY USER BACKUP OBLIGATION: PRISM OPERATES AS A LOCAL-FIRST FILE SYSTEM UTILITY. YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT YOU ARE SOLELY AND EXCLUSIVELY RESPONSIBLE FOR MAINTAINING INDEPENDENT, REDUNDANT, AND VERIFIED EXTERNAL BACKUPS OF ALL YOUR VAULTS, NOTES, AND MEDIA ATTACHMENTS. YOU ARE STRONGLY ADVISED TO ROUTINELY EXPORT YOUR DATA USING PRISM\'S BUILT-IN "VAULT EXPORT" FEATURE (GENERATING OFFLINE ZIP ARCHIVES) AND TO MAINTAIN SEPARATE MANUAL COPIES ON EXTERNAL PHYSICAL STORAGE OR INDEPENDENT CLOUD BACKUP REPOSITORIES.',
                  ),
                  const SizedBox(height: 24),

                  // ── Section 4 ───────────────────────────────────────────────
                  _buildSection(
                    context,
                    title: '4. AUDIO RECORDING & WIRETAP INDEMNIFICATION',
                    items: [
                      _buildTermsItem(
                        context,
                        title: 'Recording Consent Compliance',
                        description:
                            'Prism includes optional microphone-based audio recording and attachment capabilities. State, federal, and international wiretap and eavesdropping laws (including the laws of California, Florida, Massachusetts, Pennsylvania, Illinois, and other two-party or all-party consent jurisdictions) strictly prohibit recording conversations without the express consent of all participating parties.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'User Representation & Indemnification',
                        description:
                            'You expressly represent and warrant that you will not utilize Prism\'s audio recording features without obtaining all legally required consents. You agree to defend, indemnify, and hold harmless Small Giant Studio, its developers, and affiliates against any and all claims, statutory penalties, damages, liabilities, costs, and legal fees arising out of or related to your recording of any conversation, individual, or acoustic event using Prism.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Section 5 ───────────────────────────────────────────────
                  _buildSection(
                    context,
                    title: '5. DATA OWNERSHIP & INTELLECTUAL PROPERTY',
                    items: [
                      _buildTermsItem(
                        context,
                        title: 'Your Content Ownership',
                        description:
                            'You retain 100% full legal ownership, copyright, and intellectual property rights in all Markdown files, notes, audio attachments, templates, and text stored within your vaults. Prism does not claim any ownership over your writing or personal files.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'Prism Intellectual Property',
                        description:
                            'Small Giant Studio retains all rights, title, and interest in and to Prism, including its application source code, interface designs, visual themes, typography styling, algorithms, and trademarks. You are granted a personal, revocable, non-exclusive, non-transferable license to use Prism on your personal devices.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Section 6 ───────────────────────────────────────────────
                  _buildSection(
                    context,
                    title: '6. BINDING ARBITRATION & CLASS ACTION WAIVER',
                    items: [
                      _buildTermsItem(
                        context,
                        title: 'Mandatory Binding Arbitration',
                        description:
                            'Except as provided below, any dispute, controversy, or claim arising out of or relating to these Terms, Prism, or any alleged data loss shall be resolved exclusively by final and binding individual arbitration administered by the American Arbitration Association ("AAA") under its Consumer Arbitration Rules. The Federal Arbitration Act (FAA) governs the interpretation and enforcement of this section.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'Class Action & Collective Relief Waiver',
                        description:
                            'YOU AND SMALL GIANT STUDIO AGREE THAT ALL DISPUTES MUST BE ARBITRATED ON AN INDIVIDUAL BASIS ONLY. NEITHER YOU NOR SMALL GIANT STUDIO SHALL BE ENTITLED TO JOIN OR CONSOLIDATE CLAIMS, ACT AS A REPRESENTATIVE OR PRIVATE ATTORNEY GENERAL, OR PROCEED IN ANY CLASS OR COLLECTIVE ARBITRATION.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'Mandatory 30-Day Informal Negotiation',
                        description:
                            'Before initiating arbitration, the claimant must first send a written Notice of Dispute describing the claim and desired relief to $contactEmail. Both parties agree to negotiate in good faith for at least thirty (30) days following receipt before commencing arbitration.',
                      ),
                      _buildTermsItem(
                        context,
                        title: '30-Day Email Opt-Out Right',
                        description:
                            'You have the right to opt out of this binding arbitration provision within thirty (30) days of first downloading or installing Prism. To opt out, you must send an email to $contactEmail with the subject line "Arbitration Opt-Out", stating your name and clear intent to opt out. If you opt out, all other provisions of these Terms remain fully binding.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'California Public Injunction Carve-Out (McGill Rule)',
                        description:
                            'Pursuant to California Supreme Court precedent (McGill v. Citibank, N.A.), if you seek public injunctive relief under California consumer protection statutes, that specific request for public injunctive relief shall be severed and litigated in state or federal court in Santa Clara County, California, staying such court proceedings until all individual arbitrable claims have been concluded.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'Governing Law & Venue',
                        description:
                            'These Terms are governed by the laws of the State of California and applicable U.S. federal law, without regard to conflict of laws rules. Any judicial proceeding not subject to arbitration shall be brought exclusively in the state or federal courts located in Santa Clara County, California.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Section 7 ───────────────────────────────────────────────
                  _buildSection(
                    context,
                    title: '7. SEVERABILITY & CONTACT',
                    items: [
                      _buildTermsItem(
                        context,
                        title: 'Severability & Entire Agreement',
                        description:
                            'If any provision of these Terms is found to be unlawful, void, or unenforceable, that provision shall be deemed severable and shall not affect the validity and enforceability of the remaining provisions. These Terms constitute the entire agreement between you and Small Giant Studio regarding Prism.',
                      ),
                      _buildTermsItem(
                        context,
                        title: 'Legal Inquiries',
                        description:
                            'For questions regarding these Terms, dispute notices, or arbitration opt-outs, please contact us at $contactEmail.',
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
                      publicTermsUrl,
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
                        Clipboard.setData(const ClipboardData(text: publicTermsUrl));
                        PrismToast.show(
                          context,
                          'Terms of Service URL copied to clipboard!',
                          icon: Icons.copy_rounded,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: DesignColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DesignColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: DesignColors.primary(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Copy URL',
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: DesignColors.primary(context),
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTypography.metadata(
            context,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: DesignColors.textSecondary(context),
          ).copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildTermsItem(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DesignTypography.body(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: DesignTypography.details(
              context,
              fontSize: 12,
              color: DesignColors.textSecondary(context),
            ).copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildConspicuousCard(
    BuildContext context, {
    required String badgeText,
    required String title,
    required String content,
  }) {
    final primaryColor = DesignColors.primary(context);
    final borderColor = DesignColors.border(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              badgeText,
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
            title,
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
            content,
            style: DesignTypography.metadata(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ).copyWith(letterSpacing: 0.3, height: 1.5),
          ),
        ],
      ),
    );
  }
}
