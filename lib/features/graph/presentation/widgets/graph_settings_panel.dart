import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../widgets/spatial_group_edit_bottom_sheet.dart';
import '../../data/spatial_group_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';


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
  int _activeTab = 0; // 0 = Forces, 1 = Groups

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
          constraints: const BoxConstraints(maxWidth: 400),
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
                    // Header Row with Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _activeTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _activeTab == 0 ? colorScheme.primary : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Forces',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: _activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                    color: _activeTab == 0
                                        ? (isDark ? PrismColors.darkText : PrismColors.lightText)
                                        : (isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => setState(() => _activeTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _activeTab == 1 ? colorScheme.primary : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Groups',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: _activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                    color: _activeTab == 1
                                        ? (isDark ? PrismColors.darkText : PrismColors.lightText)
                                        : (isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                    
                    if (_activeTab == 0) ...[
                      // Repulsion Force Slider
                      _buildSlider(
                        title: 'Repulsion Force',
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
                        title: 'Link Spring Distance',
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
                        title: 'Spring Stiffness',
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
                        title: 'Simulation Damping',
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
                              'Drag to Pin',
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
                      const SizedBox(height: 8),

                      // Footer Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onResetDefaults,
                            icon: const Icon(Icons.restart_alt_rounded, size: 16),
                            label: Text(
                              'Reset Defaults',
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
                    ] else ...[
                      _buildGroupsTab(context, isDark, colorScheme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsTab(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final groupsAsync = ref.watch(spatialGroupsListProvider);
    final mappingsAsync = ref.watch(spatialGroupMappingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spatial Groups',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? PrismColors.darkTextSecondary : PrismColors.lightTextSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const SpatialGroupEditBottomSheet(),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text(
                'New Group',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No spatial groups created yet.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? PrismColors.darkTextTertiary : PrismColors.lightTextTertiary,
                    ),
                  ),
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final nodeIds = mappingsAsync.value?[group.id] ?? [];
                  final resolvedColor = _resolveColor(group.colorHex);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // Color Indicator Circle
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: resolvedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? PrismColors.darkText : PrismColors.lightText,
                                ),
                              ),
                              Text(
                                '${nodeIds.length} notes',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? PrismColors.darkTextTertiary : PrismColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => SpatialGroupEditBottomSheet(group: group),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 16),
                          color: colorScheme.error,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Group'),
                                content: Text('Are you sure you want to delete "${group.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(spatialGroupRepositoryProvider).deleteSpatialGroup(group.id);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading groups: $e'),
        ),
      ],
    );
  }

  Color _resolveColor(String key) {
    final theme = Theme.of(context);
    switch (key.toUpperCase()) {
      case '#PRIMARY':
        return theme.colorScheme.primary;
      case '#ROSE':
        return theme.colorScheme.error;
      case '#GREEN':
        return theme.colorScheme.secondary;
      case '#AMBER':
        return theme.colorScheme.tertiary;
      default:
        var hexColor = key.replaceAll('#', '');
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor';
        }
        final val = int.tryParse(hexColor, radix: 16);
        return val != null ? Color(val) : theme.colorScheme.primary;
    }
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
