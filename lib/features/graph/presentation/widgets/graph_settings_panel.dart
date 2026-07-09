import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/graph_color_provider.dart';
import 'package:prism/l10n/l10n.dart';


class GraphSettingsPanel extends ConsumerStatefulWidget {
  final double repulsionRate;
  final double repulsionPercentage;
  final double attractionRate;
  final double damping;
  
  final ValueChanged<double> onChangedRepulsionRate;
  final ValueChanged<double> onChangedRepulsionPercentage;
  final ValueChanged<double> onChangedAttractionRate;
  final ValueChanged<double> onChangedDamping;
  
  final VoidCallback onClose;
  final VoidCallback onResetDefaults;
  final VoidCallback onReLayout;

  const GraphSettingsPanel({
    super.key,
    required this.repulsionRate,
    required this.repulsionPercentage,
    required this.attractionRate,
    required this.damping,
    required this.onChangedRepulsionRate,
    required this.onChangedRepulsionPercentage,
    required this.onChangedAttractionRate,
    required this.onChangedDamping,
    required this.onClose,
    required this.onResetDefaults,
    required this.onReLayout,
  });

  @override
  ConsumerState<GraphSettingsPanel> createState() => _GraphSettingsPanelState();
}

class _GraphSettingsPanelState extends ConsumerState<GraphSettingsPanel> {
  // Local state copy to ensure drag changes only rebuild the panel
  late double _localRepulsionRate;
  late double _localRepulsionPercentage;
  late double _localAttractionRate;
  late double _localDamping;
  @override
  void initState() {
    super.initState();
    _syncLocalValues();
  }

  @override
  void didUpdateWidget(covariant GraphSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent values are reset or changed outside, sync them
    if (oldWidget.repulsionRate != widget.repulsionRate ||
        oldWidget.repulsionPercentage != widget.repulsionPercentage ||
        oldWidget.attractionRate != widget.attractionRate ||
        oldWidget.damping != widget.damping) {
      _syncLocalValues();
    }
  }

  void _syncLocalValues() {
    _localRepulsionRate = widget.repulsionRate;
    _localRepulsionPercentage = widget.repulsionPercentage;
    _localAttractionRate = widget.attractionRate;
    _localDamping = widget.damping;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 10,
      right: 16,
      left: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? PrismColors.darkSurface : PrismColors.lightSurface)
                      .withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? PrismColors.darkBorder : PrismColors.lightBorder)
                        .withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Title (Fixed at the top)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.graph_settings_panel_title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? PrismColors.darkText : PrismColors.lightText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Scrollable settings body
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Repulsion Force Slider
                            _buildSlider(
                              title: context.l10n.graph_settings_panel_repulsion_force,
                              value: _localRepulsionRate,
                              min: 0.05,
                              max: 1.5,
                              divisions: 29,
                              label: _localRepulsionRate.toStringAsFixed(2),
                              onChanged: (val) {
                                setState(() => _localRepulsionRate = val);
                                widget.onChangedRepulsionRate(val);
                              },
                              onChangeEnd: (val) => widget.onReLayout(),
                            ),

                            // Spring rest length (via Repulsion Percentage)
                            _buildSlider(
                              title: context.l10n.graph_settings_panel_link_spring_distance,
                              value: _localRepulsionPercentage,
                              min: 0.3,
                              max: 2.0,
                              divisions: 34,
                              label: '${(120.0 * (1.0 / (_localRepulsionPercentage + 0.1))).toStringAsFixed(0)}px',
                              onChanged: (val) {
                                setState(() => _localRepulsionPercentage = val);
                                widget.onChangedRepulsionPercentage(val);
                              },
                              onChangeEnd: (val) => widget.onReLayout(),
                            ),

                            // Attraction Rate Slider
                            _buildSlider(
                              title: context.l10n.graph_settings_panel_spring_stiffness,
                              value: _localAttractionRate,
                              min: 0.05,
                              max: 0.9,
                              divisions: 34,
                              label: _localAttractionRate.toStringAsFixed(2),
                              onChanged: (val) {
                                setState(() => _localAttractionRate = val);
                                widget.onChangedAttractionRate(val);
                              },
                              onChangeEnd: (val) => widget.onReLayout(),
                            ),

                            // Friction Damping Slider
                            _buildSlider(
                              title: context.l10n.graph_settings_panel_simulation_damping,
                              value: _localDamping,
                              min: 0.7,
                              max: 0.98,
                              divisions: 28,
                              label: _localDamping.toStringAsFixed(2),
                              onChanged: (val) {
                                setState(() => _localDamping = val);
                                widget.onChangedDamping(val);
                              },
                              onChangeEnd: (val) => widget.onReLayout(),
                            ),
                            
                            // Drag to Pin Switch
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.l10n.graph_settings_panel_drag_to_pin,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                                    ),
                                  ),
                                  Switch(
                                    value: ref.watch(dragToPinEnabledProvider).valueOrNull ?? false,
                                    activeThumbColor: colorScheme.primary,
                                    onChanged: (val) {
                                      ref.read(dragToPinEnabledProvider.notifier).setDragToPinEnabled(val);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 16),

                            // Color By Dropdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.l10n.graph_settings_panel_color_by,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                                  ),
                                ),
                                DropdownButton<String>(
                                  key: const ValueKey('graph_color_mode_dropdown'),
                                  value: ref.watch(graphColorModeProvider).valueOrNull ?? 'none',
                                  dropdownColor: isDark ? PrismColors.darkSurface : PrismColors.lightSurface,
                                  underline: const SizedBox(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? PrismColors.darkText : PrismColors.lightText,
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(graphColorModeProvider.notifier).setColorMode(val);
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'none', child: Text('None')),
                                    DropdownMenuItem(value: 'folders', child: Text('Folders')),
                                    DropdownMenuItem(value: 'tags', child: Text('Tags')),
                                  ],
                                ),
                              ],
                            ),

                            // Tag Colors List
                            if (ref.watch(graphColorModeProvider).valueOrNull == 'tags') ...[
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.graph_settings_panel_tag_colors,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? PrismColors.darkText : PrismColors.lightText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Consumer(
                                builder: (context, ref, child) {
                                  final tagsAsync = ref.watch(discoveredTagsProvider);
                                  return tagsAsync.when(
                                    data: (tags) {
                                      if (tags.isEmpty) {
                                        return Text(
                                          context.l10n.graph_settings_panel_no_tags,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                                          ),
                                        );
                                      }
                                      final userTagColors = ref.watch(tagColorsProvider).valueOrNull ?? {};
                                      return Container(
                                        constraints: const BoxConstraints(maxHeight: 120),
                                        child: SingleChildScrollView(
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: tags.map((tag) {
                                              final currentColor = userTagColors[tag];
                                              return InkWell(
                                                onTap: () {
                                                  _showColorPicker(context, ref, tag);
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: (isDark ? PrismColors.darkBorder : PrismColors.lightBorder)
                                                        .withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: currentColor != null && currentColor.isNotEmpty
                                                              ? _parseHexColor(currentColor)
                                                              : Colors.grey.withValues(alpha: 0.5),
                                                          border: Border.all(
                                                            color: isDark ? Colors.white24 : Colors.black12,
                                                            width: 1,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '#$tag',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? PrismColors.darkText : PrismColors.lightText,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Loading'),
                                      ),
                                    ),
                                    error: (_, _) => const SizedBox(),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footer Row (Fixed at the bottom)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: widget.onResetDefaults,
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: Text(
                            context.l10n.graph_settings_panel_reset_defaults,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                        TactileWrapper(
                          onTap: widget.onReLayout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Re-layout',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final userTagColors = ref.read(tagColorsProvider).valueOrNull ?? {};
    final currentColor = userTagColors[tag] ?? '';
    
    final hexController = TextEditingController(text: currentColor);
    final formKey = GlobalKey<FormState>();

    final presets = [
      ('#F87171', 'Red'),
      ('#FB923C', 'Orange'),
      ('#4ADE80', 'Green'),
      ('#2DD4BF', 'Teal'),
      ('#60A5FA', 'Blue'),
      ('#C084FC', 'Purple'),
      ('#F472B6', 'Pink'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? PrismColors.darkSurface : PrismColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tag Color: #$tag',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? PrismColors.darkText : PrismColors.lightText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Color swatches row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: presets.map((preset) {
                      final isSelected = currentColor.toLowerCase() == preset.$1.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(tagColorsProvider.notifier).setTagColor(tag, preset.$1);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _parseHexColor(preset.$1),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isDark ? Colors.white24 : Colors.black12),
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Custom hex input field
                Form(
                  key: formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: hexController,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? PrismColors.darkText : PrismColors.lightText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. #FF6B6B',
                            labelText: 'Custom Hex Color',
                            labelStyle: GoogleFonts.inter(
                              color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            final clean = val.trim();
                            final hexRegex = RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');
                            if (!hexRegex.hasMatch(clean)) {
                              return 'Invalid hex color format';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() == true) {
                            String hex = hexController.text.trim();
                            if (hex.isNotEmpty && !hex.startsWith('#')) {
                              hex = '#$hex';
                            }
                            ref.read(tagColorsProvider.notifier).setTagColor(tag, hex);
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Reset/Clear button
                TextButton(
                  onPressed: () {
                    ref.read(tagColorsProvider.notifier).setTagColor(tag, '');
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    context.l10n.graph_settings_panel_reset_hsl,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.red[300] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseHexColor(String hexString) {
    if (hexString.isEmpty) return Colors.transparent;
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }



  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.15),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}