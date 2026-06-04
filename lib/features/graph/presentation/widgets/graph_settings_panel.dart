import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';

class GraphSettingsPanel extends StatefulWidget {
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
  State<GraphSettingsPanel> createState() => _GraphSettingsPanelState();
}

class _GraphSettingsPanelState extends State<GraphSettingsPanel> {
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
          constraints: const BoxConstraints(maxWidth: 400),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface)
                      .withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder)
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
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Graph Forces Settings',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
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
