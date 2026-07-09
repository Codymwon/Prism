import 'dart:async';
import 'package:flutter/material.dart';
import '../design_system/design_system.dart';
import '../../core/theme/app_theme.dart';
import 'app_shell.dart';

/// Theme-aware navbar-anchored Prism Toast notification system.
class PrismToast {
  static OverlayEntry? _currentEntry;
  static int _currentToastId = 0;

  /// Shows a beautiful custom toast notification anchored to the navbar if present.
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    dismiss();

    final overlayState = Overlay.of(context);
    final hasNavbar = context.findAncestorWidgetOfExactType<AppShell>() != null;
    final toastId = ++_currentToastId;

    final entry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          icon: icon,
          hasNavbar: hasNavbar,
          onDismiss: () {
            if (_currentToastId == toastId) {
              dismiss();
            }
          },
          duration: duration,
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Explicitly dismisses the currently active toast.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final bool hasNavbar;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    this.icon,
    required this.hasNavbar,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isExiting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controller.forward();

    _timer = Timer(widget.duration, () {
      if (mounted) {
        _exit();
      }
    });
  }

  void _exit() {
    if (_isExiting) return;
    setState(() => _isExiting = true);
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomOffset = widget.hasNavbar ? 88.0 : 28.0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset + MediaQuery.of(context).viewInsets.bottom,
      child: Center(
        child: GestureDetector(
          onTap: _exit,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 12),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (isDark ? PrismColors.darkSurface : PrismColors.lightSurface)
                      .withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? PrismColors.darkBorder : PrismColors.lightBorder)
                        .withValues(alpha: 0.8),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 16,
                        color: DesignColors.primary(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.message,
                        style: DesignTypography.body(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? PrismColors.darkText : PrismColors.lightText,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
}
