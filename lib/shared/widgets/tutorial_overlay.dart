import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:prism/l10n/l10n.dart';
import '../../shared/design_system/design_system.dart';
import '../../shared/widgets/tactile_wrapper.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Rect Function(Size screenSize) getTargetRect;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.getTargetRect,
  });
}

class SpotlightTutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  const SpotlightTutorialOverlay({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.onSkipped,
  });

  @override
  State<SpotlightTutorialOverlay> createState() => _SpotlightTutorialOverlayState();
}

class _SpotlightTutorialOverlayState extends State<SpotlightTutorialOverlay> {
  int _currentStepIndex = 0;

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final currentStep = widget.steps[_currentStepIndex];
    final targetRect = currentStep.getTargetRect(screenSize);

    // Dynamic placement of the instruction card
    // If the spotlight is on the top half of the screen, place the card on the bottom half, and vice versa.
    final targetCenterY = targetRect.center.dy;
    final isTargetInTopHalf = targetCenterY < screenSize.height / 2;

    final primary = DesignColors.primary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: context.l10n.shared_tutorial_overlay_label,
      child: Stack(
        children: [
          // 1. Semi-transparent dimming layer with cutout spotlight
          IgnorePointer(
            ignoring: false, // User must interact with the tutorial overlay actions
            child: CustomPaint(
              size: screenSize,
              painter: SpotlightPainter(
                targetRect: targetRect,
                barrierColor: Colors.black.withValues(alpha: isDark ? 0.75 : 0.6),
                glowColor: primary,
              ),
            ),
          ),

          // 2. Click shield behind everything except spotlight & card to advance or prevent random taps
          Positioned.fill(
            child: GestureDetector(
              onTap: _nextStep,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.shrink(),
            ),
          ),

          // 3. Spotlight Target Highlight Tappable Area
          Positioned.fromRect(
            rect: targetRect.inflate(8.0),
            child: GestureDetector(
              onTap: _nextStep,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 4. Beautiful Instructional Card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: 20,
            right: 20,
            top: isTargetInTopHalf ? targetRect.bottom + 24 : null,
            bottom: !isTargetInTopHalf ? (screenSize.height - targetRect.top) + 24 : null,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DesignColors.surface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: DesignColors.border(context),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Indicator & Skip Button Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                           child: Text(
                            context.l10n.shared_tutorial_overlay_step_counter(_currentStepIndex + 1, widget.steps.length),
                            style: DesignTypography.metadata(
                              context,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onSkipped,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            context.l10n.shared_tutorial_overlay_skip_tour,
                            style: DesignTypography.body(
                              context,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DesignColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title + Pulsing Icon Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStep.icon,
                            color: primary,
                            size: 20,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.1, 1.1),
                              duration: 1000.ms,
                            ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentStep.title,
                            style: DesignTypography.heading(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DesignColors.text(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description text
                    Text(
                      currentStep.description,
                      style: DesignTypography.body(
                        context,
                        fontSize: 13.5,
                        height: 1.5,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_currentStepIndex > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: TactileWrapper(
                              style: TactileFeedbackStyle.standard,
                              onTap: () {
                                setState(() {
                                  _currentStepIndex--;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: DesignColors.surfaceVariant(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: DesignColors.border(context)),
                                ),
                                 child: Text(
                                  context.l10n.shared_tutorial_overlay_back_button,
                                  style: DesignTypography.body(
                                    context,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: DesignColors.text(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        TactileWrapper(
                          style: TactileFeedbackStyle.highImpact,
                          onTap: _nextStep,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentStepIndex == widget.steps.length - 1
                                      ? context.l10n.shared_tutorial_overlay_got_it_button
                                      : context.l10n.shared_tutorial_overlay_next_button,
                                  style: DesignTypography.heading(
                                    context,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _currentStepIndex == widget.steps.length - 1
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate(key: ValueKey(_currentStepIndex)).fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0, duration: 250.ms),
          ),
        ],
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Color barrierColor;
  final Color glowColor;

  SpotlightPainter({
    required this.targetRect,
    required this.barrierColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = barrierColor;

    // Full screen background path
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Spotlight hole path (rounded rectangle matching target with slight padding)
    final paddedRect = targetRect.inflate(8.0);
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(paddedRect, const Radius.circular(16)));

    // Combined path with target cut out
    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(combinedPath, paint);

    // Glowing border outline
    final borderPaint = Paint()
      ..color = glowColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(paddedRect, const Radius.circular(16)), borderPaint);

    // Outer glow aura
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.15)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(RRect.fromRectAndRadius(paddedRect, const Radius.circular(16)), glowPaint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.barrierColor != barrierColor ||
        oldDelegate.glowColor != glowColor;
  }
}
