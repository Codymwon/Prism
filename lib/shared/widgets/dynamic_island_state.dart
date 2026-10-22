import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prism_toast.dart';
import 'island_menu.dart';
import 'quick_capture_bottom_sheet.dart';

/// Active sub-deck within the Dynamic Island Vault Hub.
enum VaultHubSubDeck {
  tools,
  workspaceSelector,
  tags,
  createFolder,
}

/// Active presentation state of the Dynamic Island.
sealed class DynamicIslandState {
  const DynamicIslandState();

  bool get isActive => this is! DynamicIslandResting;
  bool get isToast => this is DynamicIslandToast;
  bool get isMenu => this is DynamicIslandMenu;
  bool get isQuickCapture => this is DynamicIslandQuickCapture;
  bool get isVaultHub => this is DynamicIslandVaultHub;
}

/// Resting state: standard 56dp capsule + independent 56dp FAB (12dp air gap).
class DynamicIslandResting extends DynamicIslandState {
  const DynamicIslandResting();
}

/// Active toast notification displayed on the upper shelf.
class DynamicIslandToast extends DynamicIslandState {
  final IslandToastData toast;
  const DynamicIslandToast(this.toast);
}

/// Active context action menu (note/folder long-press).
class DynamicIslandMenu extends DynamicIslandState {
  final IslandMenuData menu;
  const DynamicIslandMenu(this.menu);
}

/// Active quick capture recording or action tiles.
class DynamicIslandQuickCapture extends DynamicIslandState {
  final QuickCaptureState qcState;
  const DynamicIslandQuickCapture(this.qcState);
}

/// Active Vault Hub displaying either tools or the in-island workspace switcher.
class DynamicIslandVaultHub extends DynamicIslandState {
  final VaultHubSubDeck subDeck;
  final bool isCreatingWorkspace;

  const DynamicIslandVaultHub({
    this.subDeck = VaultHubSubDeck.tools,
    this.isCreatingWorkspace = false,
  });

  DynamicIslandVaultHub copyWith({
    VaultHubSubDeck? subDeck,
    bool? isCreatingWorkspace,
  }) {
    return DynamicIslandVaultHub(
      subDeck: subDeck ?? this.subDeck,
      isCreatingWorkspace: isCreatingWorkspace ?? this.isCreatingWorkspace,
    );
  }
}

/// Unified Riverpod notifier coordinating all Dynamic Island modal decks,
/// animations, transitions, and subdeck navigation.
class DynamicIslandNotifier extends Notifier<DynamicIslandState> {
  @override
  DynamicIslandState build() => const DynamicIslandResting();

  void showToast(IslandToastData toast) {
    if (state is DynamicIslandQuickCapture) {
      ref.read(quickCaptureNotifierProvider.notifier).dismiss();
    }
    state = DynamicIslandToast(toast);
  }

  void showMenu(IslandMenuData menu) {
    if (state is DynamicIslandQuickCapture) {
      ref.read(quickCaptureNotifierProvider.notifier).dismiss();
    }
    state = DynamicIslandMenu(menu);
  }

  void openQuickCapture() {
    state = const DynamicIslandQuickCapture(
      QuickCaptureState(
        isOpen: true,
        mode: QuickCaptureMode.actions,
      ),
    );
  }

  void updateQuickCapture(QuickCaptureState qcState) {
    if (qcState.isOpen) {
      state = DynamicIslandQuickCapture(qcState);
    } else {
      if (state is DynamicIslandQuickCapture) {
        state = const DynamicIslandResting();
      }
    }
  }

  void openVaultHub([VaultHubSubDeck subDeck = VaultHubSubDeck.tools]) {
    if (state is DynamicIslandQuickCapture) {
      ref.read(quickCaptureNotifierProvider.notifier).dismiss();
    }
    state = DynamicIslandVaultHub(subDeck: subDeck);
  }

  void switchVaultHubSubDeck(
    VaultHubSubDeck subDeck, {
    bool isCreatingWorkspace = false,
  }) {
    state = DynamicIslandVaultHub(
      subDeck: subDeck,
      isCreatingWorkspace: isCreatingWorkspace,
    );
  }

  void setCreatingWorkspace(bool creating) {
    if (state is DynamicIslandVaultHub) {
      final current = state as DynamicIslandVaultHub;
      state = current.copyWith(isCreatingWorkspace: creating);
    }
  }

  void toggleVaultHub() {
    if (state is DynamicIslandVaultHub) {
      dismiss();
    } else {
      openVaultHub();
    }
  }

  void toggleQuickCapture() {
    if (state is DynamicIslandQuickCapture) {
      dismiss();
    } else {
      openQuickCapture();
    }
  }

  void dismiss() {
    if (state is DynamicIslandQuickCapture) {
      ref.read(quickCaptureNotifierProvider.notifier).dismiss();
    }
    state = const DynamicIslandResting();
  }
}

final dynamicIslandControllerProvider =
    NotifierProvider<DynamicIslandNotifier, DynamicIslandState>(
  DynamicIslandNotifier.new,
);
