import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/vault_export_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final exportSheetControllerProvider =
    AsyncNotifierProvider.autoDispose<ExportSheetController, VaultExportResult?>(
  ExportSheetController.new,
);

// ─── Controller ───────────────────────────────────────────────────────────────

/// AsyncNotifier that drives the export bottom sheet state.
///
/// Responsibilities:
///   - Pro-gate enforcement (ZIP/PDF formats require Pro subscription)
///   - Delegates the actual export work to [VaultExportService]
///   - Folds [Either] result into [AsyncData] / [AsyncError] state
///
/// Security (S1): any filesystem path logging is debug-only (wrapped in assert).
class ExportSheetController extends AutoDisposeAsyncNotifier<VaultExportResult?> {
  @override
  Future<VaultExportResult?> build() async => null;

  Future<void> run(ExportFormat format, {required dynamic context}) async {
    // 🔒 Pro-gate: ZIP and PDF exports require an active Pro subscription.
    // Enforcement lives here in the controller, NOT in the widget layer.
    final isPro = ref.read(isProProvider);
    if (AppConfig.enableSubscriptions && !isPro && format != ExportFormat.json) {
      // Navigate to paywall and abort — the widget reacts to state, not navigate.
      // ignore: use_build_context_synchronously
      GoRouter.of(context as dynamic).push('/settings/paywall');
      return;
    }

    state = const AsyncLoading();

    final result = await ref.read(vaultExportServiceProvider).export(
      format,
      onProgress: (_, _) {
        // No-op: UI shows indeterminate CircularProgressIndicator.
        // Isolate.run cannot stream progress back — a single spinner is correct.
      },
    );

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (exportResult) => AsyncData(exportResult),
    );

    // 🔒 Security S1: never log savedPath in release builds.
    assert(() {
      if (kDebugMode) {
        result.fold(
          (f) => debugPrint('[ExportSheetController] export failed: $f'),
          (r) => debugPrint('[ExportSheetController] saved to: ${r.savedPath}'),
        );
      }
      return true;
    }());
  }
}
