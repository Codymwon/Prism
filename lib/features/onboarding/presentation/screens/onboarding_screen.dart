import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../widgets/vault_setup_form.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSettingUp = false;
  bool _showVaultSetup = false;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Absolute Privacy',
      subtitle: 'Privacy-First Notebook',
      description: 'Your notes live completely private on your device in standard Markdown. No accounts, no tracking, pure offline speed.',
      icon: Icons.shield_outlined,
      gradientColors: [const Color(0xFFE07A5F), const Color(0xFFF2CC8F)],
    ),
    OnboardingSlide(
      title: 'Wikilinks & Backlinks',
      subtitle: 'Visual Relational Thinking',
      description: 'Connect thoughts effortlessly using [[wikilinks]]. Explore relationships dynamically with automatic backlink indexes.',
      icon: Icons.hub_outlined,
      gradientColors: [const Color(0xFF81B29A), const Color(0xFF3D5A80)],
    ),
    OnboardingSlide(
      title: 'Warm Editorial Theme',
      subtitle: 'Friction-Free Interface',
      description: 'Crafted with premium typography and beautiful palettes—Clean Paper, Midnight OLED, and the warm Sepia theme.',
      icon: Icons.auto_stories_outlined,
      gradientColors: [const Color(0xFFC8A97E), const Color(0xFF5C3D2E)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: _isSettingUp
            ? _buildSetupLoading(colorScheme)
            : _showVaultSetup
                ? VaultSetupForm(
                    onStartSetup: () => setState(() => _isSettingUp = true),
                    onEndSetup: () {
                      if (mounted) {
                        setState(() => _isSettingUp = false);
                      }
                    },
                  )
                : Column(
                    children: [
                      // Upper Top Skip Button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextButton(
                            onPressed: () => setState(() => _showVaultSetup = true),
                            child: Text(
                              'Skip',
                              style: DesignTypography.body(
                                context,
                                color: DesignColors.textSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Carousel
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (idx) => setState(() => _currentPage = idx),
                          itemCount: _slides.length,
                          itemBuilder: (context, idx) => _buildSlide(_slides[idx]),
                        ),
                      ),

                      // Bottom Controls Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Dots indicator
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: _slides.length,
                              effect: ExpandingDotsEffect(
                                dotColor: DesignColors.border(context).withValues(alpha: 0.5),
                                activeDotColor: colorScheme.primary,
                                dotHeight: 8,
                                dotWidth: 8,
                                expansionFactor: 3,
                                spacing: 6,
                              ),
                              onDotClicked: (index) => _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                            ),

                            // Action Button
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _currentPage == _slides.length - 1
                                  ? TactileWrapper(
                                      key: const ValueKey('start_btn'),
                                      style: TactileFeedbackStyle.highImpact,
                                      onTap: () => setState(() => _showVaultSetup = true),
                                      child: FloatingActionButton.extended(
                                        onPressed: () {},
                                        label: Text(
                                          'Start Writing',
                                          style: DesignTypography.heading(
                                            context,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  : TactileWrapper(
                                      key: const ValueKey('next_btn'),
                                      style: TactileFeedbackStyle.standard,
                                      onTap: () => _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      ),
                                      child: FloatingActionButton(
                                        onPressed: () {},
                                        backgroundColor: DesignColors.surface(context),
                                        foregroundColor: colorScheme.primary,
                                        elevation: 1,
                                        shape: const CircleBorder(),
                                        child: const Icon(Icons.chevron_right_rounded, size: 28),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant Glassmorphic Icon Container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: slide.gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: 56,
              color: Colors.white,
            ),
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),

          // Subtitle (curated sub-brand)
          Text(
            slide.subtitle.toUpperCase(),
            style: DesignTypography.metadata(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DesignColors.primary(context),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),

          // Main Title
          Text(
            slide.title,
            style: DesignTypography.display(
              context,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: DesignColors.text(context),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: DesignTypography.body(
              context,
              fontSize: 14,
              height: 1.6,
              color: DesignColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildSetupLoading(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Setting up Meridian…',
            style: DesignTypography.heading(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparing onboarding guides and setting up workspace.',
            style: DesignTypography.details(
              context,
              fontSize: 12,
              color: DesignColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });
}
