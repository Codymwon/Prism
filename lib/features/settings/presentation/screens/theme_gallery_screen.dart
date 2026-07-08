import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/settings_provider.dart';
import 'package:prism/l10n/l10n.dart';

class ThemeGalleryScreen extends ConsumerStatefulWidget {
  const ThemeGalleryScreen({super.key});

  @override
  ConsumerState<ThemeGalleryScreen> createState() => _ThemeGalleryScreenState();
}

class _ThemeGalleryScreenState extends ConsumerState<ThemeGalleryScreen> {
  // Current active preview tab (0 = Notes List, 1 = Editor, 2 = Graph Map)
  int _previewTab = 0;
  
  // Currently selected preview theme type (defaults to active theme)
  AppThemeType? _selectedPreviewThemeType;
  
  // Whether previewing premium colors in the mockup is enabled
  bool _livePreviewMode = false;

  bool _isThemeLocked(AppThemeType type) {
    return type != AppThemeType.system &&
        type != AppThemeType.light &&
        type != AppThemeType.dark;
  }

  void _handleThemeTap(AppThemeType type, bool isPro) {
    final isLocked = _isThemeLocked(type);

    if (isLocked && !isPro) {
      if (_livePreviewMode) {
        setState(() {
          _selectedPreviewThemeType = type;
        });
      } else {
        context.push('/settings/paywall');
      }
    } else {
      setState(() {
        _selectedPreviewThemeType = type;
      });
    }
  }

  Future<void> _applySelectedTheme(bool isPro) async {
    final type = (_selectedPreviewThemeType ?? ref.read(themeStateProvider)) as AppThemeType;
    final isLocked = _isThemeLocked(type);

    if (isLocked && !isPro) {
      context.push('/settings/paywall');
    } else {
      await ref.read(themeStateProvider.notifier).setTheme(type);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.settings_theme_gallery_applied_success),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeType = ref.watch(themeStateProvider);
    final isPro = ref.watch(isProProvider);
    final fontFamily = ref.watch(fontFamilyProvider);

    final currentPreviewTheme = _selectedPreviewThemeType ?? activeThemeType;
    final previewThemeData = AppTheme.resolve(currentPreviewTheme, fontFamily).themeData;

    // List of Light Editorial Themes: (type, name, primaryColor, backgroundColor, textColor)
    final lightEditorials = [
      (AppThemeType.sepia, 'Sepia Warmth', const Color(0xFF5C3D2E), const Color(0xFFFAF6EE), const Color(0xFF2A1F19)),
      (AppThemeType.arctic, 'Arctic Clean', const Color(0xFF3A8FA8), const Color(0xFFF4F8FB), const Color(0xFF152632)),
      (AppThemeType.blush, 'Blush', const Color(0xFFB0637A), const Color(0xFFFDF8F8), const Color(0xFF2E1F24)),
      (AppThemeType.matcha, 'Matcha', const Color(0xFF3D6146), const Color(0xFFF4F7F4), const Color(0xFF1D2E22)),
    ];

    // List of Dark Editorial Themes: (type, name, primaryColor, backgroundColor, textColor)
    final darkEditorials = [
      (AppThemeType.forest, 'Forest Moss', const Color(0xFF81B29A), const Color(0xFF141C18), const Color(0xFFDEEDE5)),
      (AppThemeType.slate, 'Slate Navy', const Color(0xFF7DAFE8), const Color(0xFF0F1117), const Color(0xFFE4EAF5)),
      (AppThemeType.noir, 'Noir Gold', const Color(0xFFC9A84C), const Color(0xFF111110), const Color(0xFFF0EDE6)),
      (AppThemeType.midnight, 'Midnight', const Color(0xFF6E7681), const Color(0xFF000000), const Color(0xFFE5E7EB)),
    ];

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: TactileWrapper(
            style: TactileFeedbackStyle.standard,
            onTap: () => _applySelectedTheme(isPro),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DesignColors.primary(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.l10n.settings_theme_gallery_apply_button,
                style: DesignTypography.body(
                  context,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
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
                          context.l10n.settings_theme_gallery_title,
                          style: DesignTypography.heading(
                            context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.l10n.settings_theme_gallery_subtitle,
                          style: DesignTypography.details(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Interactive Screen Mockup Selector (Tabs) ────────────────
                  if (_livePreviewMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.settings_theme_gallery_live_preview_header,
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
                    ),
                  
                  // Live Scaffold Preview Card wrapped in Theme widget to override colors
                  if (_livePreviewMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Theme(
                          data: previewThemeData,
                          child: _AppMockupPreview(tabIndex: _previewTab),
                        )
                        .animate(key: ValueKey(_previewTab))
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.03, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
                      ),
                    ),
                  
                  // Live Preview Mode Toggle Switch
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.settings_theme_gallery_try_premium_label,
                              style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.settings_theme_gallery_live_preview_toggle,
                                style: DesignTypography.body(context, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 20,
                                width: 36,
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: _livePreviewMode,
                                    activeThumbColor: DesignColors.primary(context),
                                    onChanged: (val) {
                                      setState(() {
                                        _livePreviewMode = val;
                                        if (!val) {
                                          _selectedPreviewThemeType = null;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Editorial Light Themes Section ─────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        context.l10n.settings_theme_gallery_light_editorial_header,
                        style: DesignTypography.metadata(
                          context,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: DesignColors.textTertiary(context),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: lightEditorials.length,
                      itemBuilder: (context, index) {
                        final theme = lightEditorials[index];
                        final isSelected = currentPreviewTheme == theme.$1;
                        final isLocked = _isThemeLocked(theme.$1) && !isPro;
                        return _GalleryThemeCard(
                          type: theme.$1,
                          name: theme.$2,
                          primaryColor: theme.$3,
                          backgroundColor: theme.$4,
                          textColor: theme.$5,
                          isSelected: isSelected,
                          isLocked: isLocked,
                          onTap: () => _handleThemeTap(theme.$1, isPro),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Editorial Dark Themes Section ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: darkEditorials.length,
                      itemBuilder: (context, index) {
                        final theme = darkEditorials[index];
                        final isSelected = currentPreviewTheme == theme.$1;
                        final isLocked = _isThemeLocked(theme.$1) && !isPro;
                        return _GalleryThemeCard(
                          type: theme.$1,
                          name: theme.$2,
                          primaryColor: theme.$3,
                          backgroundColor: theme.$4,
                          textColor: theme.$5,
                          isSelected: isSelected,
                          isLocked: isLocked,
                          onTap: () => _handleThemeTap(theme.$1, isPro),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
          _buildTabButton(0, context.l10n.settings_theme_gallery_tab_list, Icons.view_list_rounded),
          _buildTabButton(1, context.l10n.settings_theme_gallery_tab_editor, Icons.edit_note_rounded),
          _buildTabButton(2, context.l10n.settings_theme_gallery_tab_graph, Icons.hub_outlined),
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
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 320,
            height: 191,
            child: switch (tabIndex) {
              0 => _buildNotesListMockup(context, theme, primaryColor),
              1 => _buildEditorMockup(context, theme, primaryColor),
              2 => _buildGraphMockup(context, theme, primaryColor),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }

  // 1. NOTES LIST SCREEN MOCKUP
  Widget _buildNotesListMockup(BuildContext context, ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Center aligned App Bar Title matching real screen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.menu_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'PRISM',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: primaryColor,
                    fontSize: 7.5,
                  ),
                ),
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 0.3,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 7,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 2.5),
                      Text(
                        'My Vault',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 6.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 8,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Icon(Icons.view_list_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
        const SizedBox(height: 8),

        // Search Bar + Sort Button Row matching real screen
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

        // Note Card item 1
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
              Text(
                'Color & Visual Fatigue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
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
                  const Spacer(),
                  Text(
                    '10 min ago • 120 words',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 7.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Partially visible Note Card item 2 to indicate scrollable list
        Expanded(
          child: Opacity(
            opacity: 0.5,
            child: Container(
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
                  Text(
                    'Workspace Setup',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Organizing physical and digital workspaces for maximum concentration and minimal visual...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 8.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
        // Editor App Bar matching real screen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.arrow_back_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'Creative Design',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                Icon(Icons.edit_outlined, size: 12, color: primaryColor), // Preview mode toggled back
              ],
            ),
          ],
        ),
        const Divider(height: 12, thickness: 0.5),

        // Editor typography markdown view matching real screen
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creative Design & Endurance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
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
                    width: 2.0,
                    height: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Parchment tones minimize ocular stress compared to harsh pure white backgrounds.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 8.5,
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

        // Backlinks Panel Mockup matching real screen
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.25), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 10, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                '2 backlinks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.expand_less_rounded,
                size: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. GRAPH MAP SCREEN MOCKUP
  Widget _buildGraphMockup(BuildContext context, ThemeData theme, Color primaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    final nodeColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Graph View Header matching real screen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Graph View',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Your connected ideas',
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
                Icon(Icons.settings_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Graph simulation viewport representation
        Expanded(
          child: Stack(
            children: [
              // Interconnecting lines matching real screen
              Positioned.fill(
                child: CustomPaint(
                  painter: _MockLinksPainter(
                    primaryColor: primaryColor,
                    secondaryColor: theme.colorScheme.outline.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // Pinned connected nodes matching real screen
              _buildGraphNode(context, theme, const Offset(90, 55), 'Endurance', primaryColor, isSelected: true),
              _buildGraphNode(context, theme, const Offset(35, 30), 'Sepia', nodeColor),
              _buildGraphNode(context, theme, const Offset(30, 85), 'Blush', nodeColor),
              _buildGraphNode(context, theme, const Offset(155, 35), 'Slate Navy', nodeColor),
              _buildGraphNode(context, theme, const Offset(160, 90), 'Matcha', nodeColor),

              // Floating Focus/Center button mockup matching real screen
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
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

  Widget _buildGraphNode(BuildContext context, ThemeData theme, Offset position, String title, Color color, {bool isSelected = false}) {
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

  Widget _buildMockTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
  bool shouldRepaint(covariant _MockLinksPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _GalleryThemeCard extends StatelessWidget {
  final AppThemeType type;
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _GalleryThemeCard({
    required this.type,
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      color: textColor,
    );

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
            // Select checkmark or lock in top right
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
              )
            else if (isLocked)
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 11,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
