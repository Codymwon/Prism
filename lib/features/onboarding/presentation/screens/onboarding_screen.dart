import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database_helper.dart';
import '../../../notes/data/note_repository.dart';
import '../../data/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSettingUp = false;

  // Vault Setup state
  bool _showVaultSetup = false;
  bool _useDefaultLocation = true;
  String _customLocationPath = '';
  final TextEditingController _vaultNameController = TextEditingController(text: 'My Vault');

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Absolute Privacy',
      subtitle: 'Privacy-First Notebook',
      description: 'Your notes live completely private on your device in standard Markdown. No accounts, no tracking, pure offline speed.',
      icon: Icons.shield_outlined,
      gradientColors: [Color(0xFFE07A5F), Color(0xFFF2CC8F)],
    ),
    OnboardingSlide(
      title: 'Wikilinks & Backlinks',
      subtitle: 'Visual Relational Thinking',
      description: 'Connect thoughts effortlessly using [[wikilinks]]. Explore relationships dynamically with automatic backlink indexes.',
      icon: Icons.hub_outlined,
      gradientColors: [Color(0xFF81B29A), Color(0xFF3D5A80)],
    ),
    OnboardingSlide(
      title: 'Warm Editorial Theme',
      subtitle: 'Friction-Free Interface',
      description: 'Crafted with premium typography and beautiful palettes—Clean Paper, Midnight OLED, and the warm Sepia theme.',
      icon: Icons.auto_stories_outlined,
      gradientColors: [Color(0xFFC8A97E), Color(0xFF5C3D2E)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _vaultNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomLocation() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        setState(() {
          _customLocationPath = path;
          _useDefaultLocation = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open folder picker: $e')),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSettingUp = true);

    try {
      final baseDir = _useDefaultLocation ? '' : _customLocationPath;
      final vaultName = _vaultNameController.text.trim().isEmpty 
          ? 'My Vault' 
          : _vaultNameController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('baseVaultsDirectory', baseDir);
      await prefs.setString('activeVaultName', vaultName);

      // Force database helper to close old global DB connection (if any)
      await DatabaseHelper.instance.closeDatabase();

      final repo = ref.read(noteRepositoryProvider);

      // Create starter notes inside the new vault directory
      await repo.createNote(
        title: 'Welcome to Meridian',
        initialContent: _welcomeNoteContent,
      );

      await repo.createNote(
        title: 'Getting Started with Wikilinks',
        initialContent: _wikilinksNoteContent,
      );

      await repo.createNote(
        title: 'The Magic of Daily Journaling',
        initialContent: _journalNoteContent,
      );

      // Save onboarding complete state
      await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    } catch (e) {
      debugPrint('Error creating starter notes: $e');
      // Fallback: save onboarding state anyway so user is not stuck
      await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    } finally {
      if (mounted) {
        setState(() => _isSettingUp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      body: SafeArea(
        child: _isSettingUp
            ? _buildSetupLoading(colorScheme, isDark)
            : _showVaultSetup
                ? _buildVaultSetupStep(colorScheme, isDark)
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
                              style: GoogleFonts.inter(
                                color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
                          itemBuilder: (context, idx) => _buildSlide(_slides[idx], isDark),
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
                                dotColor: isDark
                                    ? MeridianColors.darkBorder.withValues(alpha: 0.5)
                                    : MeridianColors.lightBorder.withValues(alpha: 0.5),
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
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
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
                                        backgroundColor: isDark
                                            ? MeridianColors.darkSurface
                                            : MeridianColors.lightSurface,
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

  Widget _buildSlide(OnboardingSlide slide, bool isDark) {
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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: isDark ? MeridianColors.darkPrimary : MeridianColors.lightPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),

          // Main Title
          Text(
            slide.title,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildVaultSetupStep(ColorScheme colorScheme, bool isDark) {
    final cardBg = isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface;
    final cardBorder = isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder;
    final textStyle = isDark ? MeridianColors.darkText : MeridianColors.lightText;
    final textSecStyle = isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header
          Text(
            'CREATE YOUR WORKSPACE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: colorScheme.primary,
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Configure Vault Location',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textStyle,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Meridian stores all your notes directly on your device. Choose where your vault folder lives. You can create and switch between multiple vaults later.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: textSecStyle,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),

          // Vault Name input
          Text(
            'Initial Vault Name',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textStyle,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _vaultNameController,
            style: GoogleFonts.inter(fontSize: 14, color: textStyle),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
              hintText: 'e.g. My Vault, Personal, Research',
              hintStyle: GoogleFonts.inter(color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cardBorder),
              ),
              prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: colorScheme.primary),
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 28),

          Text(
            'Storage Directory Location',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textStyle,
            ),
          ),
          const SizedBox(height: 12),

          // Selection Cards
          Column(
            children: [
              // Card 1: Default
              TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: () => setState(() => _useDefaultLocation = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _useDefaultLocation ? colorScheme.primary : cardBorder,
                      width: _useDefaultLocation ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _useDefaultLocation ? colorScheme.primaryContainer : cardBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.offline_pin_outlined, color: _useDefaultLocation ? colorScheme.primary : textSecStyle, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default Storage (Recommended)',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: textStyle),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recommended. Kept safe in the app\'s internal documents sandbox folder.',
                              style: GoogleFonts.inter(fontSize: 12, color: textSecStyle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card 2: Custom
              TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: () async {
                  if (_useDefaultLocation) {
                    await _pickCustomLocation();
                  } else {
                    setState(() => _useDefaultLocation = false);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !_useDefaultLocation ? colorScheme.primary : cardBorder,
                      width: !_useDefaultLocation ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !_useDefaultLocation ? colorScheme.primaryContainer : cardBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.create_new_folder_outlined, color: !_useDefaultLocation ? colorScheme.primary : textSecStyle, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Custom Local Folder',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: textStyle),
                                ),
                                if (!_useDefaultLocation)
                                  GestureDetector(
                                    onTap: _pickCustomLocation,
                                    child: Text(
                                      'Change',
                                      style: GoogleFonts.inter(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              !_useDefaultLocation && _customLocationPath.isNotEmpty
                                  ? _customLocationPath
                                  : 'Select any local folder (perfect for syncing with Obsidian, Syncthing, etc.)',
                              style: GoogleFonts.inter(fontSize: 12, color: textSecStyle),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),

          // Confirm Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TactileWrapper(
              style: TactileFeedbackStyle.highImpact,
              onTap: (!_useDefaultLocation && _customLocationPath.isEmpty)
                  ? _pickCustomLocation
                  : () {
                      if (_vaultNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid name for your vault.')),
                        );
                        return;
                      }
                      _completeOnboarding();
                    },
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Text(
                  (!_useDefaultLocation && _customLocationPath.isEmpty)
                      ? 'Select Custom Directory'
                      : 'Confirm & Initialize Workspace',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }

  Widget _buildSetupLoading(ColorScheme colorScheme, bool isDark) {
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
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparing onboarding guides and setting up workspace.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- Starter Notes Content ---

  static const String _welcomeNoteContent = '''# Welcome to Meridian

Meridian is a private, offline-first personal workspace for your thoughts and journals. All notes are saved as standard Markdown files directly on your device, giving you complete ownership and security.
1. **Absolute Privacy**: All notes live on your device as standard Markdown files.
2. **Wikilink Relationships**: Connect your notes dynamically using `[[` links.
3. **Immersive Aesthetics**: Beautiful themes designed to let you focus on writing.

## What is Meridian?
Meridian is designed to be a quiet space for your thoughts. Unlike traditional linear note-taking apps, it allows you to connect ideas together to form an interconnected network of your thoughts.

## Next Steps
- Try exploring [[Getting Started with Wikilinks]] to learn how to connect thoughts.
- Check out [[The Magic of Daily Journaling]] to learn about calendar logs.

#notes #welcome''';

  static const String _wikilinksNoteContent = '''# Getting Started with Wikilinks

Wikilinks are the foundation of relational thinking in Meridian. They allow you to build connections between ideas effortlessly.

## How to Create a Link
1. While typing, open two square brackets: `[[`
2. Type the name of another note.
3. Close the brackets: `]]`

For example, this link points back to [[Welcome to Meridian]].

## Backlinks and Ghost Notes
- **Backlinks**: Open the panel at the bottom of the editor to see all other notes that link to the current note.
- **Ghost Notes**: If you link to a note that doesn't exist yet, Meridian creates a "ghost placeholder" for it. It will fully blossom once you open and write in it!

#wikilinks #tutorial''';

  static const String _journalNoteContent = '''# The Magic of Daily Journaling

Daily Journaling is a structured habit of reflection. Meridian integrates your daily logs directly into your notes.

## Daily Note Habits
- Use the **Journal** tab to open today's dedicated calendar note.
- Jot down raw thoughts, tasks, and bookmarks.
- Tag your entries with #journal or #reflection to organize them.

## Connect Your Thoughts
Don't let your daily reflections stay isolated! Link today's journal entry to other notes in your system. For instance:
- "Today I spent time writing and connecting thoughts in [[Welcome to Meridian]]."

#journal #productivity''';
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
