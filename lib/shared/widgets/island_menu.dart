import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/design_system.dart';
import 'app_shell.dart';
import 'prism_toast.dart';
import 'dynamic_island_state.dart';

/// Single action item inside an Island Context Action Deck.
class IslandMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const IslandMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Data model representing an active Dynamic Island context menu.
class IslandMenuData {
  final int id;
  final String title;
  final IconData? icon;
  final List<IslandMenuItem> items;

  const IslandMenuData({
    required this.id,
    required this.title,
    this.icon,
    required this.items,
  });
}

/// Riverpod notifier coordinating active Dynamic Island context menu state across the app.
class IslandMenuNotifier extends Notifier<IslandMenuData?> {
  int _idCounter = 0;

  @override
  IslandMenuData? build() {
    final state = ref.watch(dynamicIslandControllerProvider);
    if (state is DynamicIslandMenu) {
      return state.menu;
    }
    return null;
  }

  void show({
    required String title,
    IconData? icon,
    required List<IslandMenuItem> items,
  }) {
    final nextId = ++_idCounter;
    final menu = IslandMenuData(
      id: nextId,
      title: title,
      icon: icon,
      items: items,
    );
    ref.read(dynamicIslandControllerProvider.notifier).showMenu(menu);
  }

  void dismiss() {
    final s = ref.read(dynamicIslandControllerProvider);
    if (s is DynamicIslandMenu) {
      ref.read(dynamicIslandControllerProvider.notifier).dismiss();
    }
  }
}

final islandMenuNotifierProvider =
    NotifierProvider<IslandMenuNotifier, IslandMenuData?>(
  IslandMenuNotifier.new,
);

/// Helper class to invoke or dismiss the Dynamic Island context menu.
/// Falls back to a standard bottom sheet when outside AppShell.
class IslandMenu {
  static void show(
    BuildContext context, {
    required String title,
    IconData? icon,
    required List<IslandMenuItem> items,
  }) {
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    final hasAppShell =
        context.findAncestorWidgetOfExactType<AppShell>() != null ||
        context.widget is AppShell;

    if (container != null && hasAppShell) {
      container.read(islandToastNotifierProvider.notifier).dismiss();
      container.read(islandMenuNotifierProvider.notifier).show(
            title: title,
            icon: icon,
            items: items,
          );
      return;
    }

    // Fallback standard modal bottom sheet on non-AppShell screens
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSpacing.borderRadiusLarge),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignSheetDragHandle(),
            ListTile(
              leading: icon != null
                  ? Icon(icon, color: DesignColors.primary(context))
                  : null,
              title: Text(
                title,
                style: DesignTypography.heading(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ...items.map(
              (item) => ListTile(
                leading: Icon(
                  item.icon,
                  color: item.isDestructive
                      ? Theme.of(context).colorScheme.error
                      : DesignColors.text(context),
                ),
                title: Text(
                  item.label,
                  style: DesignTypography.body(
                    context,
                    color: item.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : DesignColors.text(context),
                    fontWeight:
                        item.isDestructive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  item.onTap();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void dismiss(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(islandMenuNotifierProvider.notifier).dismiss();
    } catch (_) {}
  }
}
