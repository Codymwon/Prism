import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../widgets/vault_setup_form.dart';
import '../widgets/onboarding_loading.dart';
import '../widgets/onboarding_slide_view.dart';
import 'package:prism/l10n/l10n.dart';

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

  List<OnboardingSlide> get _slides => [
    OnboardingSlide(
      title: context.l10n.onboarding_screen_slide1_title,
      subtitle: context.l10n.onboarding_screen_slide1_subtitle,
      description: context.l10n.onboarding_screen_slide1_desc,
      icon: Icons.shield_outlined,
      gradientColors: [const Color(0xFFE07A5F), const Color(0xFFF2CC8F)],
      visualType: 'privacy',
    ),
    OnboardingSlide(
      title: context.l10n.onboarding_screen_slide2_title,
      subtitle: context.l10n.onboarding_screen_slide2_subtitle,
      description: context.l10n.onboarding_screen_slide2_desc,
      icon: Icons.hub_outlined,
      gradientColors: [const Color(0xFF81B29A), const Color(0xFF3D5A80)],
      visualType: 'wikilinks',
    ),
    OnboardingSlide(
      title: context.l10n.onboarding_screen_slide3_title,
      subtitle: context.l10n.onboarding_screen_slide3_subtitle,
      description: context.l10n.onboarding_screen_slide3_desc,
      icon: Icons.lens_blur_rounded,
      gradientColors: [const Color(0xFF7C6FF7), const Color(0xFFA197F9)],
      visualType: 'graph',
    ),
    OnboardingSlide(
      title: context.l10n.onboarding_screen_slide4_title,
      subtitle: context.l10n.onboarding_screen_slide4_subtitle,
      description: context.l10n.onboarding_screen_slide4_desc,
      icon: Icons.history_edu_outlined,
      gradientColors: [const Color(0xFFFF9800), const Color(0xFFFF5722)],
      visualType: 'journal',
    ),
    OnboardingSlide(
      title: context.l10n.onboarding_screen_slide5_title,
      subtitle: context.l10n.onboarding_screen_slide5_subtitle,
      description: context.l10n.onboarding_screen_slide5_desc,
      icon: Icons.auto_stories_outlined,
      gradientColors: [const Color(0xFFC8A97E), const Color(0xFF5C3D2E)],
      visualType: 'themes',
    ),
    OnboardingSlide(
      title: context.l10n.onboarding_screen_slide6_title,
      subtitle: context.l10n.onboarding_screen_slide6_subtitle,
      description: context.l10n.onboarding_screen_slide6_desc,
      icon: Icons.keyboard_voice_rounded,
      gradientColors: [const Color(0xFF4EA8DE), const Color(0xFF5390D9)],
      visualType: 'productivity',
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
        child: Stack(
          children: [
            if (_showVaultSetup)
              VaultSetupForm(
                onStartSetup: () => setState(() => _isSettingUp = true),
                onEndSetup: () {
                  if (mounted) {
                    setState(() => _isSettingUp = false);
                  }
                },
              )
            else
              Column(
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
                      itemBuilder: (context, idx) => OnboardingSlideView(slide: _slides[idx]),
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
                                  semanticLabel: context.l10n.onboarding_screen_start_writing_semantic,
                                  onTap: () => setState(() => _showVaultSetup = true),
                                  child: ExcludeSemantics(
                                    child: FloatingActionButton.extended(
                                      onPressed: () {},
                                      label: Text(
                                        context.l10n.onboarding_screen_start_writing_label,
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
                                  ),
                                )
                              : TactileWrapper(
                                  key: const ValueKey('next_btn'),
                                  style: TactileFeedbackStyle.standard,
                                  semanticLabel: context.l10n.onboarding_screen_next_slide_semantic,
                                  onTap: () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  ),
                                  child: ExcludeSemantics(
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (_isSettingUp)
              Positioned.fill(
                child: ColoredBox(
                  color: DesignColors.background(context),
                  child: const OnboardingLoading(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}