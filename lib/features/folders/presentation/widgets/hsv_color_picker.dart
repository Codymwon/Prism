import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HsvColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const HsvColorPickerDialog({super.key, required this.initialColor});

  @override
  State<HsvColorPickerDialog> createState() => _HsvColorPickerDialogState();
}

class _HsvColorPickerDialogState extends State<HsvColorPickerDialog> {
  late double _hue; // 0 - 360
  late double _saturation; // 0 - 1
  late double _value; // 0 - 1
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController = TextEditingController(text: _colorToHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _updateFromHex(String hex) {
    final cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 6) {
      final colorVal = int.tryParse('FF$cleanHex', radix: 16);
      if (colorVal != null) {
        final newColor = Color(colorVal);
        final hsv = HSVColor.fromColor(newColor);
        setState(() {
          _hue = hsv.hue;
          _saturation = hsv.saturation;
          _value = hsv.value;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87,
    );

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF262628) : const Color(0xFFFDFBFA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Select Color',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Color Display & Hex Input Row
            Row(
              children: [
                // Color Circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5DEC9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _currentColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Hex text field
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    onChanged: _updateFromHex,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'HEX CODE',
                      labelStyle: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      prefixText: '# ',
                      prefixStyle: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3EFE8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- HUE SLIDER ---
            Text('HUE (${_hue.round()}°)', style: textStyle),
            const SizedBox(height: 8),
            _buildHueSlider(),
            const SizedBox(height: 16),

            // --- SATURATION SLIDER ---
            Text('SATURATION (${(_saturation * 100).round()}%)', style: textStyle),
            const SizedBox(height: 8),
            _buildSaturationSlider(),
            const SizedBox(height: 16),

            // --- VALUE SLIDER ---
            Text('BRIGHTNESS (${(_value * 100).round()}%)', style: textStyle),
            const SizedBox(height: 8),
            _buildValueSlider(),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _currentColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 2,
                  ),
                  child: Text(
                    'Select',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build slider with rainbow background
  Widget _buildHueSlider() {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ),
      ),
      child: SliderTheme(
        data: _sliderThemeData(),
        child: Slider(
          value: _hue,
          min: 0.0,
          max: 360.0,
          onChanged: (val) {
            setState(() {
              _hue = val;
              _hexController.text = _colorToHex(_currentColor);
            });
          },
        ),
      ),
    );
  }

  // Build slider with black/white/hue background
  Widget _buildSaturationSlider() {
    final pureHueColor = HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();
    return Container(
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.white, pureHueColor],
        ),
      ),
      child: SliderTheme(
        data: _sliderThemeData(),
        child: Slider(
          value: _saturation,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _saturation = val;
              _hexController.text = _colorToHex(_currentColor);
            });
          },
        ),
      ),
    );
  }

  // Build slider with black to pure color background
  Widget _buildValueSlider() {
    final pureHueColor = HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor();
    return Container(
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.black, pureHueColor],
        ),
      ),
      child: SliderTheme(
        data: _sliderThemeData(),
        child: Slider(
          value: _value,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _value = val;
              _hexController.text = _colorToHex(_currentColor);
            });
          },
        ),
      ),
    );
  }

  SliderThemeData _sliderThemeData() {
    return const SliderThemeData(
      trackHeight: 16,
      activeTrackColor: Colors.transparent,
      inactiveTrackColor: Colors.transparent,
      thumbColor: Colors.white,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 10,
        elevation: 3,
        pressedElevation: 5,
      ),
      overlayColor: Colors.black12,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
    );
  }
}
