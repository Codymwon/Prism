import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/design_system.dart';
import 'app_shell.dart';
import 'island_menu.dart';

/// Active data model for the Dynamic Island toast.
class IslandToastData {
  final int id;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Duration duration;

  const IslandToastData({
    required this.id,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.duration = const Duration(seconds: 3),
  });

  IslandToastData copyWith({
    int? id,
    String? message,
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    return IslandToastData(
      id: id ?? this.id,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      actionText: actionText ?? this.actionText,
      onAction: onAction ?? this.onAction,
      duration: duration ?? this.duration,
    );
  }
}

/// Riverpod notifier coordinating active Dynamic Island toast state across the application.
class IslandToastNotifier extends Notifier<IslandToastData?> {
  int _idCounter = 0;

  @override
  IslandToastData? build() => null;

  void show({
    required String message,
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final nextId = ++_idCounter;
    state = IslandToastData(
      id: nextId,
      message: message,
      icon: icon,
      actionText: actionText,
      onAction: onAction,
      duration: duration,
    );
  }

  void dismiss() {
    state = null;
  }
}

final islandToastNotifierProvider =
    NotifierProvider<IslandToastNotifier, IslandToastData?>(
  IslandToastNotifier.new,
);

/// Theme-aware Dynamic Island toast notification system.
class PrismToast {
  static OverlayEntry? _currentEntry;
  static int _currentToastId = 0;

  /// Shows a beautiful Dynamic Island toast notification.
  /// If inside an AppShell with a navbar capsule, it expands the navbar capsule.
  /// On standalone screens (Editor, Onboarding), it falls back to an adaptive bottom-docked drawer.
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Attempt Riverpod dispatch
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    final hasAppShell = context.findAncestorWidgetOfExactType<AppShell>() != null;

    if (container != null && hasAppShell) {
      dismissOverlay();
      container.read(islandMenuNotifierProvider.notifier).dismiss();
      container.read(islandToastNotifierProvider.notifier).show(
        message: message,
        icon: icon,
        actionText: actionText,
        onAction: onAction,
        duration: duration,
      );
      return;
    }

    // When outside AppShell, ensure any lingering island state is dismissed
    if (container != null) {
      container.read(islandToastNotifierProvider.notifier).dismiss();
      container.read(islandMenuNotifierProvider.notifier).dismiss();
    }

    // Fallback overlay for screens outside AppShell
    dismissOverlay();
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    final toastId = ++_currentToastId;
    final entry = OverlayEntry(
      builder: (ctx) {
        return _FallbackToastWidget(
          message: message,
          icon: icon,
          actionText: actionText,
          onAction: onAction,
          onDismiss: () {
            if (_currentToastId == toastId) {
              dismissOverlay();
            }
          },
          duration: duration,
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Explicitly dismisses the currently active toast across both overlay and provider.
  static void dismiss([BuildContext? context]) {
    dismissOverlay();
    if (context != null) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(islandToastNotifierProvider.notifier).dismiss();
      } catch (_) {}
    }
  }

  /// Dismisses standalone overlay entry if present.
  static void dismissOverlay() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _FallbackToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;
  final Duration duration;

  const _FallbackToastWidget({
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_FallbackToastWidget> createState() => _FallbackToastWidgetState();
}

class _FallbackToastWidgetState extends State<_FallbackToastWidget>
    with SingleTickerProviderStateMixin {
  static const _kFallbackSpringCurve = Cubic(0.34, 1.45, 0.64, 1.0);
  static const _kFallbackDismissCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  late final AnimationController _controller;
  bool _isExiting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.selectionClick();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
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
    HapticFeedback.selectionClick();
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPosition = bottomInset + keyboardInset + 14.0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPosition,
      child: Center(
        child: GestureDetector(
          onTap: _exit,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
              _exit();
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = CurvedAnimation(
                parent: _controller,
                curve: _kFallbackSpringCurve,
                reverseCurve: _kFallbackDismissCurve,
              ).value;

              return Opacity(
                opacity: _controller.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 16),
                  child: Transform.scale(
                    scale: 0.85 + (0.15 * value),
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DesignColors.surface(context).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: DesignColors.border(context).withValues(alpha: 0.8),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 16,
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
                              color: DesignColors.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (widget.actionText != null) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              widget.onAction?.call();
                              _exit();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DesignColors.primary(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.actionText!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
