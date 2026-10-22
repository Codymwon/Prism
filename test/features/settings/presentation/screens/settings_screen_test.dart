import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/settings/presentation/screens/settings_screen.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prism/core/services/data_deletion_service.dart';

class MockDataDeletionService extends Fake implements DataDeletionService {
  bool executeFullResetCalled = false;

  @override
  Future<void> executeFullReset() async {
    executeFullResetCalled = true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': '/mock/vaults',
    });
  });

  Widget buildTestableWidget({
    required bool isPro,
    DataDeletionService? dataDeletionService,
  }) {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/paywall',
          builder: (context, state) => const Scaffold(body: Text('Paywall Screen')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        isProProvider.overrideWith((ref) => isPro),
        if (dataDeletionService != null)
          dataDeletionServiceProvider.overrideWithValue(dataDeletionService),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('displays Try Prism Pro when non-Pro', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(isPro: false));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Prism Pro Active'), findsNothing);
  });

  testWidgets('displays Prism Pro Active when Pro', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(isPro: true));
    await tester.pumpAndSettle();

    expect(find.text('Prism Pro Active'), findsOneWidget);
    expect(find.text('Upgrade to Pro'), findsNothing);
  });

  testWidgets('Settings ListView has bottom padding to clear the floating navbar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(isPro: false));
    await tester.pumpAndSettle();

    // Find the main scrollable ListView and check its padding
    final listViewFinder = find.byType(ListView).first;
    final listView = tester.widget<ListView>(listViewFinder);
    final padding = listView.padding;

    // Should have at least 80 bottom padding so content clears the floating nav bar
    expect(padding, isNotNull);
    expect(padding!.resolve(TextDirection.ltr).bottom, greaterThanOrEqualTo(80.0));
  });

  testWidgets('displays Danger Zone and Delete All Data & Reset tile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(isPro: false));
    await tester.pumpAndSettle();

    // Scroll to the bottom to find the Danger Zone
    final deleteTile = find.text('Delete All Data & Reset');
    await tester.scrollUntilVisible(deleteTile, 300);
    await tester.pumpAndSettle();

    expect(find.text('DANGER ZONE'), findsOneWidget);
    expect(deleteTile, findsOneWidget);
    expect(find.text('Permanently erase local vaults, credentials, and settings'), findsOneWidget);
  });

  testWidgets('tapping Delete All Data & Reset shows confirmation dialog and requires typing DELETE',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockDeletionService = MockDataDeletionService();

    await tester.pumpWidget(buildTestableWidget(
      isPro: false,
      dataDeletionService: mockDeletionService,
    ));
    await tester.pumpAndSettle();

    // Scroll to and tap Delete All Data & Reset
    final deleteTile = find.text('Delete All Data & Reset');
    await tester.scrollUntilVisible(deleteTile, 500);
    await tester.pumpAndSettle();
    await tester.tap(deleteTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Delete All Data & Reset?'), findsOneWidget);
    expect(find.text('Delete Everything'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Confirm button should be disabled initially
    final deleteButtonFinder = find.widgetWithText(ElevatedButton, 'Delete Everything');
    expect(tester.widget<ElevatedButton>(deleteButtonFinder).enabled, isFalse);

    // Type something other than DELETE
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, 'NO');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(deleteButtonFinder).enabled, isFalse);

    // Type DELETE
    await tester.enterText(textFieldFinder, 'DELETE');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(deleteButtonFinder).enabled, isTrue);

    // Tap Delete Everything
    await tester.tap(deleteButtonFinder);
    await tester.pump(); // Start progress
    await tester.pumpAndSettle(); // Finish reset

    // Verify executeFullReset was called and routed to onboarding
    expect(mockDeletionService.executeFullResetCalled, isTrue);
    expect(find.text('Onboarding Screen'), findsOneWidget);
  });
}
