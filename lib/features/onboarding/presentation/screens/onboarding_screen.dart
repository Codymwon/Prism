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
      description: 'Your notes live completely private on your device in standard Markdown. No accounts, no tracking, pure offline speed and security.',
      icon: Icons.shield_outlined,
      gradientColors: [const Color(0xFFE07A5F), const Color(0xFFF2CC8F)],
      visualType: 'privacy',
    ),
    OnboardingSlide(
      title: 'Wikilink Connections',
      subtitle: 'Visual Relational Thinking',
      description: 'Connect thoughts effortlessly by typing [[wikilinks]]. Explore relationships dynamically with automatic backlink indexes.',
      icon: Icons.hub_outlined,
      gradientColors: [const Color(0xFF81B29A), const Color(0xFF3D5A80)],
      visualType: 'wikilinks',
    ),
    OnboardingSlide(
      title: 'Thought Graph Map',
      subtitle: 'Interactive Mindmap',
      description: 'Watch your connected notes blossom into an interactive force-directed graph. Visually navigate and spot patterns in your thinking.',
      icon: Icons.lens_blur_rounded,
      gradientColors: [const Color(0xFF7C6FF7), const Color(0xFFA197F9)],
      visualType: 'graph',
    ),
    OnboardingSlide(
      title: 'Editorial Aesthetics',
      subtitle: 'Friction-Free Design',
      description: 'Crafted with premium typography and beautiful palettes—Clean Paper, Midnight OLED, and the warm Sepia theme.',
      icon: Icons.auto_stories_outlined,
      gradientColors: [const Color(0xFFC8A97E), const Color(0xFF5C3D2E)],
      visualType: 'themes',
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
          // Theme-Aware Animated Visual Box
          Container(
            width: double.infinity,
            height: 200,
            alignment: Alignment.center,
            child: OnboardingSlideVisual(type: slide.visualType),
          ),
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
  final String visualType;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.visualType,
  });
}

// ─── Theme-Aware Enhanced Visual Mockups ─────────────────────────────────────

class OnboardingSlideVisual extends StatelessWidget {
  final String type;

  const OnboardingSlideVisual({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);
    final surfaceVariant = DesignColors.surfaceVariant(context);
    final accentGreen = DesignColors.accentGreen(context);
    final accentAmber = DesignColors.accentAmber(context);

    switch (type) {
      case 'privacy':
        return SizedBox(
          width: 200,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Folder background shape
              Positioned(
                bottom: 10,
                child: Container(
                  width: 140,
                  height: 110,
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Folder tab
                      Positioned(
                        top: -9,
                        left: 12,
                        child: Container(
                          width: 45,
                          height: 10,
                          decoration: BoxDecoration(
                            color: surfaceVariant,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: Border(
                              top: BorderSide(color: border, width: 1.5),
                              left: BorderSide(color: border, width: 1.5),
                              right: BorderSide(color: border, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Document files falling in dynamically
              Positioned(
                top: 15,
                left: 60,
                child: _buildMiniDoc(context, 'notes.md', accentGreen)
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 1000.ms)
                    .slideY(begin: -0.5, end: 0.5, duration: 1500.ms, curve: Curves.easeIn)
                    .fadeOut(delay: 1100.ms, duration: 400.ms),
              ),
              Positioned(
                top: 5,
                right: 55,
                child: _buildMiniDoc(context, 'journal.md', primary)
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 1200.ms)
                    .slideY(begin: -0.4, end: 0.6, duration: 1800.ms, delay: 400.ms, curve: Curves.easeIn)
                    .fadeOut(delay: 1300.ms, duration: 500.ms),
              ),
              // Lock Overlay Badge
              Positioned(
                bottom: 35,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 32,
                    color: primary,
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),
              ),
            ],
          ),
        );
      case 'wikilinks':
        return SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left Note Card
              Positioned(
                left: 10,
                child: _buildInteractiveNoteCard(context, 'Ideas', Icons.lightbulb_outline_rounded, primary),
              ),
              // Right Note Card
              Positioned(
                right: 10,
                child: _buildInteractiveNoteCard(context, 'Brain Map', Icons.hub_outlined, accentGreen),
              ),
              // Double brackets floating & pulsing
              Positioned(
                top: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    '[[ wikilink ]]',
                    style: DesignTypography.body(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.05, 1.05),
                      duration: 1200.ms,
                      curve: Curves.easeInOut,
                    ),
              ),
              // Glowing connection beam
              Positioned(
                bottom: 45,
                left: 80,
                right: 80,
                child: SizedBox(
                  height: 20,
                  child: CustomPaint(
                    painter: _BeamPainter(color: primary),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'graph':
        return SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Connection lines underneath
              Positioned.fill(
                child: CustomPaint(
                  painter: _GraphLinesPainter(
                    color: border,
                    center: const Offset(110, 90),
                    points: const [
                      Offset(40, 40),
                      Offset(180, 45),
                      Offset(50, 140),
                      Offset(170, 135),
                    ],
                  ),
                ),
              ),
              // Center Node
              Center(
                child: _buildGraphNode(context, 'Brain', Icons.lens_blur_rounded, primary, 28)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -4, end: 4, duration: 1800.ms, curve: Curves.easeInOut),
              ),
              // Top-Left Node
              Positioned(
                top: 25,
                left: 25,
                child: _buildGraphNode(context, 'Journal', Icons.calendar_today_rounded, accentGreen, 20)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 3, end: -3, duration: 1500.ms, curve: Curves.easeInOut),
              ),
              // Top-Right Node
              Positioned(
                top: 30,
                right: 25,
                child: _buildGraphNode(context, 'Work', Icons.work_outline_rounded, accentAmber, 20)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -3, end: 3, duration: 1700.ms, curve: Curves.easeInOut),
              ),
              // Bottom-Left Node
              Positioned(
                bottom: 25,
                left: 35,
                child: _buildGraphNode(context, 'Quotes', Icons.format_quote_rounded, Colors.purple, 20)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -2, end: 4, duration: 1600.ms, curve: Curves.easeInOut),
              ),
              // Bottom-Right Node
              Positioned(
                bottom: 20,
                right: 35,
                child: _buildGraphNode(context, 'Tasks', Icons.check_circle_outline_rounded, Colors.teal, 20)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 4, end: -2, duration: 1400.ms, curve: Curves.easeInOut),
              ),
            ],
          ),
        );
      case 'themes':
        return SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Card: Clean Paper (Light theme style)
              Positioned(
                left: 15,
                top: 45,
                child: _buildThemeMockCard(
                  context: context,
                  title: 'Clean Paper',
                  bgColor: const Color(0xFFF9F6F0),
                  textColor: const Color(0xFF2C2C2C),
                  borderColor: const Color(0xFFE6DED4),
                  tagBgColor: const Color(0xFFEBE5DC),
                  fontFamily: 'Inter',
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: -8, duration: 2500.ms, curve: Curves.easeInOut),
              ),
              // Middle Card: Midnight OLED (Dark theme style)
              Positioned(
                right: 15,
                top: 30,
                child: _buildThemeMockCard(
                  context: context,
                  title: 'Midnight OLED',
                  bgColor: const Color(0xFF0C0C0C),
                  textColor: const Color(0xFFECECEC),
                  borderColor: const Color(0xFF222222),
                  tagBgColor: const Color(0xFF1E1E1E),
                  fontFamily: 'JetBrains Mono',
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: 8, duration: 2500.ms, curve: Curves.easeInOut),
              ),
              // Top Card: Warm Sepia (Sepia theme style)
              Positioned(
                top: 15,
                child: _buildThemeMockCard(
                  context: context,
                  title: 'Warm Sepia',
                  bgColor: const Color(0xFFFAF5EC),
                  textColor: const Color(0xFF433422),
                  borderColor: const Color(0xFFE8DEC9),
                  tagBgColor: const Color(0xFFF3EAD5),
                  fontFamily: 'Lora',
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -6, duration: 2000.ms, curve: Curves.easeInOut),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMiniDoc(BuildContext context, String name, Color accent) {
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);

    return Container(
      width: 80,
      height: 45,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 10, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 6,
                  color: DesignColors.text(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(width: 50, height: 4, color: DesignColors.textSecondary(context).withValues(alpha: 0.3)),
          const SizedBox(height: 4),
          Container(width: 30, height: 4, color: DesignColors.textSecondary(context).withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildInteractiveNoteCard(BuildContext context, String title, IconData icon, Color color) {
    final border = DesignColors.border(context);
    final surface = DesignColors.surface(context);

    return Container(
      width: 75,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: DesignTypography.heading(
              context,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(width: 40, height: 3, color: DesignColors.textSecondary(context).withValues(alpha: 0.2)),
          const SizedBox(height: 3),
          Container(width: 25, height: 3, color: DesignColors.textSecondary(context).withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildGraphNode(BuildContext context, String label, IconData icon, Color color, double size) {
    final text = DesignColors.text(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(
            icon,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: DesignColors.surfaceVariant(context).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: DesignColors.border(context), width: 0.5),
          ),
          child: Text(
            label,
            style: DesignTypography.metadata(
              context,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeMockCard({
    required BuildContext context,
    required String title,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required Color tagBgColor,
    required String fontFamily,
    Color? shadowColor,
  }) {
    return Container(
      width: 120,
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            title,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          // Horizontal mock text lines
          Container(width: 80, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(width: 95, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(width: 60, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          // Tag pills
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#writing',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#ideas',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  final Color color;
  _BeamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashWidth = 5.0;
    final dashSpace = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2), Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GraphLinesPainter extends CustomPainter {
  final Color color;
  final Offset center;
  final List<Offset> points;

  _GraphLinesPainter({
    required this.color,
    required this.center,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawLine(center, pt, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
