import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

enum TactileFeedbackStyle {
  standard,     // Bouncy shrink (0.97), light/selection haptic
  highImpact,   // Deeper bouncy shrink (0.94) with elastic overshoot rebound, medium haptic
  longPressLift,// Lifting scale-up (1.03) with elevated shadow, heavy haptic
  destructive,  // Red warning overlay recoil, warning haptic pattern
}

class TactileWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final TactileFeedbackStyle style;

  const TactileWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.style = TactileFeedbackStyle.standard,
  });

  @override
  ConsumerState<TactileWrapper> createState() => _TactileWrapperState();
}

class _TactileWrapperState extends ConsumerState<TactileWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _redFlashAnimation;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );

    // Dynamic scale mappings based on style
    double endScale = 0.97;
    if (widget.style == TactileFeedbackStyle.highImpact) {
      endScale = 0.94;
    } else if (widget.style == TactileFeedbackStyle.longPressLift) {
      endScale = 1.03; // Liftoff lifts up!
    } else if (widget.style == TactileFeedbackStyle.destructive) {
      endScale = 0.96;
    }

    _scaleAnimation = Tween<double>(begin: 1.0, end: endScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: widget.style == TactileFeedbackStyle.highImpact
            ? Curves.elasticOut
            : Curves.easeIn,
      ),
    );

    _redFlashAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    final hapticsEnabled = ref.read(hapticsEnabledProvider);
    if (!hapticsEnabled) return;

    switch (widget.style) {
      case TactileFeedbackStyle.standard:
        HapticFeedback.selectionClick();
        break;
      case TactileFeedbackStyle.highImpact:
        HapticFeedback.mediumImpact();
        break;
      case TactileFeedbackStyle.longPressLift:
        HapticFeedback.heavyImpact();
        break;
      case TactileFeedbackStyle.destructive:
        // Destructive warning double pulse
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 60), () {
          HapticFeedback.lightImpact();
        });
        break;
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null && widget.onDoubleTap == null) return;
    _isLongPressed = false;
    _controller.forward();
    _triggerHaptic();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null && widget.onLongPress == null && widget.onDoubleTap == null) return;
    if (!_isLongPressed) {
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap == null && widget.onLongPress == null && widget.onDoubleTap == null) return;
    _controller.reverse();
  }

  void _handleLongPress() {
    if (widget.onLongPress == null) return;
    _isLongPressed = true;
    _triggerHaptic();
    // Rebound back smoothly
    _controller.reverse();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    // If no callbacks are registered, just return the child unchanged
    if (widget.onTap == null && widget.onLongPress == null && widget.onDoubleTap == null) {
      return widget.child;
    }

    Widget resultWidget = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    // Apply specific enhancements for specific states
    if (widget.style == TactileFeedbackStyle.destructive) {
      resultWidget = AnimatedBuilder(
        animation: _redFlashAnimation,
        builder: (context, childWidget) {
          return Stack(
            children: [
              childWidget!,
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: _redFlashAnimation.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: resultWidget,
      );
    } else if (widget.style == TactileFeedbackStyle.longPressLift) {
      // Elevate the shadow during long press liftoff
      resultWidget = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, childWidget) {
          final isLifted = _scaleAnimation.value > 1.0;
          return Container(
            decoration: BoxDecoration(
              boxShadow: isLifted
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: childWidget,
          );
        },
        child: resultWidget,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: widget.onLongPress != null ? _handleLongPress : null,
        onDoubleTap: widget.onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: resultWidget,
      ),
    );
  }
}
