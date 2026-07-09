import 'dart:async';
import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/settings/presentation/screens/vault_export_screen.dart';
import 'package:prism/features/settings/presentation/providers/export_provider.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/core/services/vault_export_service.dart';

// Fake ExportSheetController to simulate different export states
class _FakeExportSheetController extends ExportSheetController {
  final AsyncValue<VaultExportResult?> initialValue;
  _FakeExportSheetController(this.initialValue);

  @override
  Future<VaultExportResult?> build() {
    if (initialValue is AsyncLoading) {
      return Completer<VaultExportResult?>().future;
    } else if (initialValue is AsyncError) {
      return Future.error((initialValue as AsyncError).error);
    } else {
      return Future.value(initialValue.valueOrNull);
    }
  }

  @override
  Future<void> run(ExportFormat format, {required dynamic context}) async {
    state = const AsyncValue.loading();
  }
}

void main() {
  Widget buildTestableWidget({
    required bool isPro,
    required AsyncValue<VaultExportResult?> exportState,
  }) {
    return ProviderScope(
      overrides: [
        isProProvider.overrideWith((ref) => isPro),
        exportSheetControllerProvider.overrideWith(
          () => _FakeExportSheetController(exportState),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VaultExportScreen(),
      ),
    );
  }

  testWidgets('renders all format options and Pro tags correctly for non-Pro user',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(
      isPro: false,
      exportState: const AsyncValue.data(null),
    ));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Export Vault'), findsWidgets); // matches appbar title and headers
    
    // Verify formats exist
    expect(find.text('JSON export'), findsOneWidget);
    expect(find.text('ZIP archive'), findsOneWidget);
    expect(find.text('Single PDF'), findsOneWidget);
    expect(find.text('PDFs in ZIP'), findsOneWidget);

    // Verify PRO badges are shown on premium options (ZIP, Single PDF, PDFs in ZIP)
    // There should be exactly 3 widgets showing text "PRO"
    expect(find.text('PRO'), findsNWidgets(3));
  });

  testWidgets('renders all format options without Pro tags for Pro user',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(
      isPro: true,
      exportState: const AsyncValue.data(null),
    ));
    await tester.pumpAndSettle();

    // Verify PRO badges are NOT shown
    expect(find.text('PRO'), findsNothing);
  });

  testWidgets('shows loading indicator when export is in progress',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(
      isPro: true,
      exportState: const AsyncValue.loading(),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Exporting…'), findsOneWidget);
  });

  testWidgets('shows success block when export completes successfully',
      (WidgetTester tester) async {
    const mockResult = VaultExportResult(
      savedPath: '/mock/path/backup.zip',
      noteCount: 42,
      bytes: 1024 * 50, // 50 KB
    );

    await tester.pumpWidget(buildTestableWidget(
      isPro: true,
      exportState: const AsyncValue.data(mockResult),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Export Complete'), findsOneWidget);
    expect(find.text('42 notes · 50.0 KB'), findsOneWidget);
    expect(find.text('/mock/path/backup.zip'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
