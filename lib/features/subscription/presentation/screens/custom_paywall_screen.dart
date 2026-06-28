import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    children: [
                      // ── Icon & Title ───────────────────────────────────────
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 20),
                      
                      Center(
                        child: Text(
                          isPro ? 'You are a Pro member!' : 'Elevate Your Notebook',
                          style: DesignTypography.display(
                            context,
                            color: DesignColors.text(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      
                      const SizedBox(height: 8),
                      
                      Center(
                        child: Text(
                          isPro 
                              ? 'Thank you for supporting Prism. All premium features are unlocked.'
                              : 'Sync across devices, switcher vault limits, custom macros, bookmarks, and premium styling.',
                          style: DesignTypography.body(
                            context,
                            color: DesignColors.textSecondary(context),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      
                      const SizedBox(height: 32),
                      
                      // ── Value Propositions List ────────────────────────────
                      _buildValueProp(
                        icon: Icons.sync_rounded,
                        title: 'E2E Google Drive Sync',
                        description: 'Sync your notes end-to-end encrypted across all your mobile and desktop devices.',
                      ),
                      _buildValueProp(
                        icon: Icons.folder_copy_rounded,
                        title: 'Unlimited Local Vaults',
                        description: 'Manage 3 or more local vaults switcher. (Free tier is limited to 2 vaults).',
                      ),
                      _buildValueProp(
                        icon: Icons.keyboard_command_key_rounded,
                        title: 'Custom Macros & Templates',
                        description: 'Build your own reflection templates and toolbar macros manager shortcuts.',
                      ),
                      _buildValueProp(
                        icon: Icons.bookmark_added_rounded,
                        title: 'Timeline Audio Bookmarks',
                        description: 'Flag bookmark details directly over your voice dictation audio waveforms.',
                      ),
                      _buildValueProp(
                        icon: Icons.style_rounded,
                        title: 'Premium Themes & Styling',
                        description: 'Access Midnight OLED, Noir Gold, arctic layouts, and custom fonts.',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ── BYOK AI Section ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignColors.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.key_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Bring Your Own Key (BYOK) AI',
                                  style: DesignTypography.body(
                                    context,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: DesignColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI features in Prism are completely free. To use cloud-grade models, input your own API key (Gemini, OpenAI, or Anthropic) — you pay your AI provider directly for the tokens you use. Prism does not proxy your traffic, ensuring absolute local privacy.',
                              style: DesignTypography.details(context),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      
                      const SizedBox(height: 32),
                      
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
                            
                            return Column(
                              children: sorted.map((pkg) => _buildPackageCard(pkg, primaryColor)).toList(),
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
                        
                        const SizedBox(height: 24),
                        
                        // ── Buy Button ───────────────────────────────────────
                        if (_selectedPackage != null)
                          TactileWrapper(
                            style: TactileFeedbackStyle.standard,
                            onTap: _isPurchasing ? () {} : () => _handlePurchase(_selectedPackage!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _isPurchasing 
                                    ? DesignColors.surfaceVariant(context) 
                                    : primaryColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isPurchasing
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: primaryColor.withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isPurchasing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
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
                          ).animate().fadeIn(delay: 250.ms),
                        
                        const SizedBox(height: 16),
                        
                        // ── Restore Button ───────────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: _isPurchasing ? null : _handleRestore,
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

  Widget _buildValueProp({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final primaryColor = DesignColors.primary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTypography.body(
                    context,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: DesignColors.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: DesignTypography.details(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05, duration: 300.ms);
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withValues(alpha: 0.05) 
              : DesignColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : DesignColors.surfaceVariant(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isYearly ? 'Yearly Access' : 'Monthly Access',
                        style: DesignTypography.body(
                          context,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: DesignColors.text(context),
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: DesignTypography.metadata(
                              context,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isYearly 
                        ? 'Best value. Pay annually, save 25%.' 
                        : 'Flexible access, cancel anytime.',
                    style: DesignTypography.details(context),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pkg.priceString,
                  style: DesignTypography.body(
                    context,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: DesignColors.text(context),
                  ),
                ),
                Text(
                  isYearly ? '/year' : '/month',
                  style: DesignTypography.details(context),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
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
