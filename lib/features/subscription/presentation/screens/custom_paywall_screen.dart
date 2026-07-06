import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/failures/subscription_failure.dart';
import '../providers/subscription_providers.dart';

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
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Center(
                        child: Text(
                          isPro ? 'You are a Pro member!' : 'Elevate Your Notebook',
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
                          isPro 
                              ? 'Thank you for supporting Prism. All premium features are unlocked.'
                              : 'Unlock cross-device sync, custom formats, and premium styling.',
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
                                  'No subscription options available currently.',
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
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Error loading products: $err',
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
                                        ),
                                      )
                                    : Text(
                                        'Upgrade Now',
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
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Subscription auto-renews until cancelled. Manage or cancel anytime in your Google Play account settings.',
                              textAlign: TextAlign.center,
                              style: DesignTypography.body(
                                context,
                                fontSize: 11,
                                color: DesignColors.textSecondary(context),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // ── Restore Button ───────────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: _isPurchasing ? null : _handleRestore,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Restore Purchases',
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                color: DesignColors.textSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
          _buildComparisonRow('E2E Google Drive Sync', free: false, pro: true),
          _buildComparisonRow('Custom Templates & Macros', free: false, pro: true),
          _buildComparisonRow('Timeline Audio Bookmarks', free: false, pro: true),
          _buildComparisonRow('Premium Themes & Fonts', free: false, pro: true),
          _buildComparisonRow('Vault Export (ZIP/PDF/JSON)', free: false, pro: true),
          _buildComparisonRow('Unlimited Vaults (Local)', free: true, pro: true),
          _buildComparisonRow('Local & BYOD AI', free: true, pro: true),
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
            'Features',
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
            'Free',
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
            'Pro',
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
                  : Text(
                      '—',
                      style: TextStyle(
                        color: DesignColors.textTertiary(context),
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: pro
                  ? Icon(Icons.check_circle_rounded, size: 15, color: primaryColor)
                  : Text(
                      '—',
                      style: TextStyle(
                        color: DesignColors.textTertiary(context),
                        fontSize: 11,
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
                  'SAVE 25%',
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
              isYearly ? 'Yearly Access' : 'Monthly Access',
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
              isYearly ? '/year' : '/month',
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
              const SnackBar(content: Text('Purchase cancelled.')),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Purchase Failed'),
                content: Text(failure.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        (status) {
          if (status.isPro) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prism Pro unlocked successfully!')),
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
              title: const Text('Restore Failed'),
              content: Text(failure.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        (status) {
          if (status.isPro) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Purchases restored. Prism Pro active!')),
            );
            context.pop(); // Close paywall
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No active purchases found to restore.')),
            );
          }
        },
      );
    }
  }
}
