import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';

class ThemeGalleryScreen extends ConsumerStatefulWidget {
  const ThemeGalleryScreen({super.key});

  @override
  ConsumerState<ThemeGalleryScreen> createState() => _ThemeGalleryScreenState();
}

class _ThemeGalleryScreenState extends ConsumerState<ThemeGalleryScreen> {
  // Current active preview tab (0 = Notes List, 1 = Editor, 2 = Graph Map)
  int _previewTab = 0;

  @override
  Widget build(BuildContext context) {
    final activeThemeType = ref.watch(themeProvider);

    // List of Light Editorial Themes: (type, name, fontFamily, primaryColor, backgroundColor, textColor)
    final lightEditorials = [
      (AppThemeType.sepia, 'Sepia Warmth', 'Lora', const Color(0xFF5C3D2E), const Color(0xFFFAF6EE), const Color(0xFF2A1F19)),
      (AppThemeType.arctic, 'Arctic Clean', 'Inter', const Color(0xFF3A8FA8), const Color(0xFFF4F8FB), const Color(0xFF152632)),
      (AppThemeType.blush, 'Blush', 'Inter', const Color(0xFFB0637A), const Color(0xFFFDF8F8), const Color(0xFF2E1F24)),
      (AppThemeType.matcha, 'Matcha', 'Inter', const Color(0xFF3D6146), const Color(0xFFF4F7F4), const Color(0xFF1D2E22)),
    ];

    // List of Dark Editorial Themes: (type, name, fontFamily, primaryColor, backgroundColor, textColor)
    final darkEditorials = [
      (AppThemeType.forest, 'Forest Moss', 'Inter', const Color(0xFF81B29A), const Color(0xFF141C18), const Color(0xFFDEEDE5)),
      (AppThemeType.slate, 'Slate Navy', 'Inter', const Color(0xFF7DAFE8), const Color(0xFF0F1117), const Color(0xFFE4EAF5)),
      (AppThemeType.noir, 'Noir Gold', 'Inter', const Color(0xFFC9A84C), const Color(0xFF111110), const Color(0xFFF0EDE6)),
      (AppThemeType.midnight, 'Midnight', 'Inter', const Color(0xFF6E7681), const Color(0xFF000000), const Color(0xFFE5E7EB)),
    ];

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
              child: Row(
                children: [
                  TactileWrapper(
                    style: TactileFeedbackStyle.standard,
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceVariant(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: DesignColors.text(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Gallery',
                          style: DesignTypography.heading(
                            context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Curated editorial layouts & typography',
                          style: DesignTypography.details(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // ── Interactive Screen Mockup Selector (Tabs) ────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LIVE SCREEN PREVIEW',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: DesignColors.textTertiary(context),
                          ),
                        ),
                        // Screen tabs selector
                        _buildSegmentedTabs(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Live Scaffold Preview Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AppMockupPreview(tabIndex: _previewTab)
                        .animate(key: ValueKey(_previewTab))
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.03, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
                  ),
                  const SizedBox(height: 24),

                  // ── Editorial Light Themes Section ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'LIGHT EDITORIAL PALETTES',
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: DesignColors.textTertiary(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: lightEditorials.length,
                      itemBuilder: (context, index) {
                        final theme = lightEditorials[index];
                        final isSelected = activeThemeType == theme.$1;
                        return _GalleryThemeCard(
                          type: theme.$1,
                          name: theme.$2,
                          fontFamily: theme.$3,
                          primaryColor: theme.$4,
                          backgroundColor: theme.$5,
                          textColor: theme.$6,
                          isSelected: isSelected,
                          onTap: () => ref.read(themeProvider.notifier).setTheme(theme.$1),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Editorial Dark Themes Section ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'DARK EDITORIAL PALETTES',
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: DesignColors.textTertiary(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: darkEditorials.length,
                      itemBuilder: (context, index) {
                        final theme = darkEditorials[index];
                        final isSelected = activeThemeType == theme.$1;
                        return _GalleryThemeCard(
                          type: theme.$1,
                          name: theme.$2,
                          fontFamily: theme.$3,
                          primaryColor: theme.$4,
                          backgroundColor: theme.$5,
                          textColor: theme.$6,
                          isSelected: isSelected,
                          onTap: () => ref.read(themeProvider.notifier).setTheme(theme.$1),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DesignColors.border(context), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(0, 'List', Icons.view_list_rounded),
          _buildTabButton(1, 'Editor', Icons.edit_note_rounded),
          _buildTabButton(2, 'Graph', Icons.hub_outlined),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _previewTab == index;
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () => setState(() => _previewTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? DesignColors.background(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? DesignColors.primary(context) : DesignColors.textSecondary(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: DesignTypography.metadata(
                context,
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? DesignColors.text(context) : DesignColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppMockupPreview extends StatelessWidget {
  final int tabIndex;

  const _AppMockupPreview({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      height: 215,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        child: switch (tabIndex) {
          0 => _buildNotesListMockup(context, theme, primaryColor),
          1 => _buildEditorMockup(context, theme, primaryColor),
          2 => _buildGraphMockup(context, theme, primaryColor),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  // 1. NOTES LIST SCREEN MOCKUP
  Widget _buildNotesListMockup(BuildContext context, ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Center aligned App Bar Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.menu_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            Text(
              'MERIDIAN',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: primaryColor,
                fontSize: 9,
              ),
            ),
            Icon(Icons.view_headline_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
        const SizedBox(height: 10),

        // Search Bar mockup
        Row(
          children: [
            Expanded(
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Text(
                      'Search notes...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Icon(Icons.swap_vert_rounded, size: 12, color: primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Folders pills row
        Row(
          children: [
            _buildMockPill(context, 'Inbox (4)', primaryColor, isSelected: true),
            const SizedBox(width: 5),
            _buildMockPill(context, '#Design', theme.colorScheme.onSurface.withValues(alpha: 0.5), isSelected: false),
            const SizedBox(width: 5),
            _buildMockPill(context, '#Journal', theme.colorScheme.onSurface.withValues(alpha: 0.5), isSelected: false),
          ],
        ),
        const SizedBox(height: 10),

        // Note Card item
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color & Visual Fatigue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Icon(Icons.push_pin_rounded, size: 10, color: primaryColor.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Warm paper tones reduce glare, making typography highly readable in direct sunlight...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 8.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildMockTag(context, '#Editorial', primaryColor),
                  const SizedBox(width: 4),
                  _buildMockTag(context, '10 min ago', theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. EDITOR SCREEN MOCKUP
  Widget _buildEditorMockup(BuildContext context, ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editor app bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.chevron_left_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  'Creative Design',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.folder_open_rounded, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Icon(Icons.menu_book_rounded, size: 13, color: primaryColor), // Preview active
              ],
            ),
          ],
        ),
        const Divider(height: 14, thickness: 0.5),

        // Editor typography markdown view
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creative Design & Endurance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'Selecting curated palettes like '),
                    TextSpan(
                      text: '[[Sepia Warmth]]',
                      style: TextStyle(
                        color: primaryColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' or Forest Moss protects visual stamina. Line width is set to '),
                    const TextSpan(
                      text: 'Comfortable',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 2.5,
                    height: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Parchment tones minimize ocular stress compared to harsh pure white backgrounds.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Formatting Toolbar mockup at bottom
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildToolbarIcon(Icons.format_bold_rounded, theme),
              _buildToolbarIcon(Icons.format_italic_rounded, theme),
              _buildToolbarIcon(Icons.format_size_rounded, theme),
              _buildToolbarIcon(Icons.link_rounded, theme),
              _buildToolbarIcon(Icons.format_list_bulleted_rounded, theme),
            ],
          ),
        ),
      ],
    );
  }

  // 3. GRAPH MAP SCREEN MOCKUP
  Widget _buildGraphMockup(BuildContext context, ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Graph View Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Graph Map',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Connected vault index',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 7.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.refresh_rounded, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Icon(Icons.tune_rounded, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Graph simulation viewport representation
        Expanded(
          child: Stack(
            children: [
              // Interconnecting lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _MockLinksPainter(
                    primaryColor: primaryColor,
                    secondaryColor: theme.colorScheme.outline.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // Pinned connected nodes
              _buildGraphNode(const Offset(90, 55), 'Endurance', primaryColor, isSelected: true),
              _buildGraphNode(const Offset(35, 30), 'Sepia', theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              _buildGraphNode(const Offset(30, 85), 'Blush', theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              _buildGraphNode(const Offset(155, 35), 'Slate Navy', theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              _buildGraphNode(const Offset(160, 90), 'Matcha', theme.colorScheme.onSurface.withValues(alpha: 0.5)),

              // Zoom center button mockup
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Icon(Icons.gps_fixed_rounded, size: 9, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGraphNode(Offset position, String title, Color color, {bool isSelected = false}) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSelected ? 8 : 6,
            height: isSelected ? 8 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 6.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, ThemeData theme) {
    return Icon(icon, size: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5));
  }

  Widget _buildMockPill(BuildContext context, String text, Color color, {required bool isSelected}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 8,
        ),
      ),
    );
  }

  Widget _buildMockTag(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 7.5,
        ),
      ),
    );
  }
}

class _MockLinksPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _MockLinksPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintPrimary = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final paintSecondary = Paint()
      ..color = secondaryColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Connect nodes
    // Center node is Endurance at dx:90 + 4 (dot half), dy:55 + 4 = (94, 59)
    const center = Offset(104, 61);
    
    // Sepia is (35 + 3, 30 + 3) = (38, 33)
    canvas.drawLine(center, const Offset(48, 35), paintPrimary);
    // Blush is (30 + 3, 85 + 3) = (33, 88)
    canvas.drawLine(center, const Offset(43, 90), paintPrimary);
    // Slate Navy is (155 + 3, 35 + 3) = (158, 38)
    canvas.drawLine(center, const Offset(170, 40), paintPrimary);
    // Matcha is (160 + 3, 90 + 3) = (163, 93)
    canvas.drawLine(center, const Offset(175, 95), paintPrimary);

    // Cross-connecting secondary nodes
    canvas.drawLine(const Offset(48, 35), const Offset(43, 90), paintSecondary);
    canvas.drawLine(const Offset(170, 40), const Offset(175, 95), paintSecondary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GalleryThemeCard extends StatelessWidget {
  final AppThemeType type;
  final String name;
  final String fontFamily;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _GalleryThemeCard({
    required this.type,
    required this.name,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle;
    if (fontFamily == 'Lora') {
      textStyle = GoogleFonts.lora(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: textColor,
      );
    } else {
      textStyle = GoogleFonts.inter(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: textColor,
      );
    }

    // Shorten visual names to fit beautifully inside compact cards
    final displayName = name.replaceFirst(' Warmth', '').replaceFirst(' Clean', '').replaceFirst(' Editorial', '').replaceFirst(' Moss', '').replaceFirst(' Navy', '').replaceFirst(' Gold', '').replaceFirst(' Latte', '').replaceFirst(' Stealth ', '');

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : DesignColors.border(context),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fontFamily == 'Lora' ? 'Serif typography' : 'Sans typography',
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        color: textColor.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Color dots representing palette in bottom left
                SizedBox(
                  height: 8,
                  width: 20,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: textColor.withValues(alpha: 0.25), width: 0.5),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4.5,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: textColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: backgroundColor.withValues(alpha: 0.35), width: 0.5),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 9.0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: backgroundColor.withValues(alpha: 0.35), width: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Select checkmark in top right
            if (isSelected)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
