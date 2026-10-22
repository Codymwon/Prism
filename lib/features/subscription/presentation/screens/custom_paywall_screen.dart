import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/failures/subscription_failure.dart';
import '../providers/subscription_providers.dart';
import 'package:prism/l10n/l10n.dart';

class CustomPaywallScreen extends ConsumerStatefulWidget {
  const CustomPaywallScreen({super.key});

  @override
  ConsumerState<CustomPaywallScreen> createState() => _CustomPaywallScreenState();
}

class _CustomPaywallScreenState extends ConsumerState<CustomPaywallScreen> {
  SubscriptionPackage? _selectedPackage;
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(availablePackagesProvider);
    final primaryColor = DesignColors.primary(context);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background Gradient Accent ───────────────────────────────────
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.08),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            
            // ── Screen Content ───────────────────────────────────────────────
            Column(
              children: [
                // ── Header Bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: DesignColors.text(context),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Prism Pro',
                        style: DesignTypography.body(
                          context,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: DesignColors.text(context),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to balance close button
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      // ── Icon & Title ───────────────────────────────────────
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.diamond_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Center(
                        child: Text(
                          isPro ? context.l10n.paywall_title_pro_active : context.l10n.paywall_title_pro_inactive,
                          style: DesignTypography.heading(
                            context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Center(
                        child: Text(
                          isPro ? context.l10n.paywall_desc_pro_active : context.l10n.paywall_desc_pro_inactive,
                          style: DesignTypography.body(
                            context,
                            color: DesignColors.textSecondary(context),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // ── Comparison Table ───────────────────────────────────
                      _buildComparisonTable(),

                      const SizedBox(height: 24),
                      
                      if (isPro) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Icon(Icons.check_circle_outline_rounded, color: primaryColor, size: 48),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // ── Product Selection Cards ───────────────────────────
                        packagesAsync.when(
                          data: (packages) {
                            if (packages.isEmpty) {
                              return Center(
                                child: Text(
                                  context.l10n.paywall_empty_packages,
                                  style: DesignTypography.body(context),
                                ),
                              );
                            }
                            
                            // Sort so Yearly is first/highlighted
                            final sorted = List<SubscriptionPackage>.from(packages);
                            sorted.sort((a, b) => b.packageType == 'yearly' ? 1 : -1);
                            
                            if (_selectedPackage == null && sorted.isNotEmpty) {
                              // Select yearly default or first package
                              final defaultPackage = sorted.firstWhere(
                                (p) => p.packageType == 'yearly',
                                orElse: () => sorted.first,
                              );
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _selectedPackage == null) {
                                  setState(() {
                                    _selectedPackage = defaultPackage;
                                  });
                                }
                              });
                            }
                            
                            return Row(
                              children: sorted.map((pkg) => Expanded(child: _buildPackageCard(pkg, primaryColor))).toList(),
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator.adaptive(semanticsLabel: 'Loading'),
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                context.l10n.paywall_error_loading(err.toString()),
                                style: DesignTypography.body(context, color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // ── Buy Button ───────────────────────────────────────
                        if (_selectedPackage != null)
                          TactileWrapper(
                            style: TactileFeedbackStyle.standard,
                            onTap: _isPurchasing ? () {} : () => _handlePurchase(_selectedPackage!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _isPurchasing 
                                    ? DesignColors.surfaceVariant(context) 
                                    : primaryColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isPurchasing
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: primaryColor.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isPurchasing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator.adaptive(
                                          strokeWidth: 2.5,
                                          semanticsLabel: 'Loading',
                                        ),
                                      )
                                    : Text(
                                        context.l10n.paywall_upgrade_button,
                                        style: DesignTypography.body(
                                          context,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 8),

                        // ── Subscription Terms Disclaimer ─────────────────────
                        Builder(
                          builder: (context) {
                            final price = _selectedPackage?.priceString ?? '\$29.99';
                            final period = (_selectedPackage?.packageType == 'monthly') ? 'month' : 'year';
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  context.l10n.paywall_disclaimer(price, period),
                                  textAlign: TextAlign.center,
                                  style: DesignTypography.body(
                                    context,
                                    fontSize: 11,
                                    color: DesignColors.textSecondary(context),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 4),

                        // ── Restore Button ───────────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: _isPurchasing ? null : _handleRestore,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            ),
                            child: Text(
                              context.l10n.paywall_restore_button,
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                color: DesignColors.textSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Legal Links Footer ──────────────────────────────
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/settings/terms'),
                              child: Text(
                                context.l10n.paywall_terms_link,
                                style: DesignTypography.details(
                                  context,
                                  fontSize: 11,
                                  color: DesignColors.textTertiary(context),
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: DesignColors.textTertiary(context),
                                ),
                              ),
                            ),
                            Text(
                              '•',
                              style: DesignTypography.details(
                                context,
                                fontSize: 11,
                                color: DesignColors.textTertiary(context),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/settings/privacy'),
                              child: Text(
                                context.l10n.paywall_privacy_link,
                                style: DesignTypography.details(
                                  context,
                                  fontSize: 11,
                                  color: DesignColors.textTertiary(context),
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: DesignColors.textTertiary(context),
                                ),
                              ),
                            ),
                            Text(
                              '•',
                              style: DesignTypography.details(
                                context,
                                fontSize: 11,
                                color: DesignColors.textTertiary(context),
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleManageSubscription,
                              child: Text(
                                context.l10n.paywall_manage_subscription,
                                style: DesignTypography.details(
                                  context,
                                  fontSize: 11,
                                  color: DesignColors.textTertiary(context),
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: DesignColors.textTertiary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.border(context), width: 0.5),
      ),
      child: Column(
        children: [
          _buildComparisonHeader(),
          const Divider(height: 16, thickness: 0.5),
          _buildComparisonRow(context.l10n.paywall_feature_sync, free: false, pro: true),
          _buildComparisonRow(context.l10n.paywall_feature_templates_macros, free: false, pro: true),
          _buildComparisonRow(context.l10n.paywall_feature_audio_bookmarks, free: false, pro: true),
          _buildComparisonRow(context.l10n.paywall_feature_themes_fonts, free: false, pro: true),
          _buildComparisonRow(context.l10n.paywall_feature_export, free: false, pro: true),
          _buildComparisonRow(context.l10n.paywall_feature_unlimited_vaults, free: true, pro: true),
          _buildComparisonRow(context.l10n.paywall_feature_local_ai, free: true, pro: true),
        ],
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            context.l10n.paywall_header_features,
            style: DesignTypography.metadata(
              context,
              fontWeight: FontWeight.w700,
              color: DesignColors.textTertiary(context),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            context.l10n.paywall_header_free,
            textAlign: TextAlign.center,
            style: DesignTypography.metadata(
              context,
              fontWeight: FontWeight.w700,
              color: DesignColors.textTertiary(context),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            context.l10n.paywall_header_pro,
            textAlign: TextAlign.center,
            style: DesignTypography.metadata(
              context,
              fontWeight: FontWeight.w700,
              color: DesignColors.textTertiary(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String feature, {required bool free, required bool pro}) {
    final primaryColor = DesignColors.primary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature,
              style: DesignTypography.body(
                context,
                fontSize: 12,
                color: DesignColors.text(context),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: free
                  ? Icon(Icons.check_circle_outline_rounded, size: 15, color: primaryColor)
                  : Semantics(
                      label: context.l10n.paywall_not_available_semantic,
                      excludeSemantics: true,
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: DesignColors.textTertiary(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: pro
                  ? Icon(Icons.check_circle_rounded, size: 15, color: primaryColor)
                  : Semantics(
                      label: context.l10n.paywall_not_available_semantic,
                      excludeSemantics: true,
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: DesignColors.textTertiary(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(SubscriptionPackage pkg, Color primaryColor) {
    final isSelected = _selectedPackage?.id == pkg.id;
    final isYearly = pkg.packageType == 'yearly';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = pkg;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withValues(alpha: 0.05) 
              : DesignColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : DesignColors.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isYearly) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.paywall_save_percentage_yearly,
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16), // Balance yearly card top badge
            ],
            Text(
              isYearly ? context.l10n.paywall_yearly_access : context.l10n.paywall_monthly_access,
              style: DesignTypography.body(
                context,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: DesignColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pkg.priceString,
              style: DesignTypography.body(
                context,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: DesignColors.text(context),
              ),
            ),
            Text(
              isYearly ? context.l10n.paywall_yearly_suffix : context.l10n.paywall_monthly_suffix,
              style: DesignTypography.details(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(SubscriptionPackage package) async {
    setState(() {
      _isPurchasing = true;
    });

    final repository = ref.read(subscriptionRepositoryProvider);
    final result = await repository.purchasePackage(package);

    if (mounted) {
      setState(() {
        _isPurchasing = false;
      });

      result.fold(
        (failure) {
          if (failure is PurchaseCancelledFailure) {
            // User cancelled quietly, no need for alert
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.paywall_purchase_cancelled)),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.paywall_purchase_failed_title),
                content: Text(failure.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.paywall_ok),
                  ),
                ],
              ),
            );
          }
        },
        (status) {
          if (status.isPro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.paywall_purchase_success)),
            );
            context.pop(); // Close paywall
          }
        },
      );
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isPurchasing = true;
    });

    final repository = ref.read(subscriptionRepositoryProvider);
    final result = await repository.restorePurchases();

    if (mounted) {
      setState(() {
        _isPurchasing = false;
      });

      result.fold(
        (failure) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.l10n.paywall_restore_failed_title),
              content: Text(failure.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.paywall_ok),
                ),
              ],
            ),
          );
        },
        (status) {
          if (status.isPro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.paywall_restore_success)),
            );
            context.pop(); // Close paywall
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.paywall_restore_empty)),
            );
          }
        },
      );
    }
  }

  Future<void> _handleManageSubscription() async {
    final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}