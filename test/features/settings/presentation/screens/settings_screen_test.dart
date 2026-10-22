import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/settings/presentation/screens/settings_screen.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/core/config/app_config.dart';
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
    AppConfig.enableSubscriptions = true;
    AppConfig.enableExternalStorage = true;
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': '/mock/vaults',
    });
  });

  tearDown(() {
    AppConfig.enableSubscriptions = false;
    AppConfig.enableExternalStorage = false;
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

  testWidgets('displays the 4 consolidated pillars with consistent headers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(isPro: false));
    await tester.pumpAndSettle();

    // Verify Pillar 1: Vaults & Storage
    expect(find.text('VAULTS & STORAGE'), findsOneWidget);
    expect(find.text('Manage Vaults'), findsOneWidget);
    expect(find.text('Vault Export'), findsOneWidget);
    expect(find.text('Manage Attachments'), findsOneWidget);

    // Verify Pillar 2: Security & Sync (subscriptions enabled in setUp)
    expect(find.text('SECURITY & SYNC'), findsOneWidget);
    expect(find.text('Security Trust Center'), findsNothing);
    expect(find.text('Cloud Sync'), findsOneWidget);

    // Verify Pillar 3: Writing & Appearance
    expect(find.text('WRITING & APPEARANCE'), findsOneWidget);
    expect(find.text('Font family'), findsOneWidget);
    expect(find.text('Editor Preferences'), findsOneWidget);

    // Scroll down to verify Pillar 4: About & Support
    final aboutHeader = find.text('ABOUT & SUPPORT');
    await tester.scrollUntilVisible(aboutHeader, 500);
    await tester.pumpAndSettle();

    expect(aboutHeader, findsOneWidget);
    expect(find.text('Contact Support & Feedback'), findsOneWidget);
    expect(find.text('Replay interactive tutorial'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Share Anonymous Diagnostics'), findsOneWidget);

    // Scroll down to verify Danger Zone
    final dangerHeader = find.text('DANGER ZONE');
    await tester.scrollUntilVisible(dangerHeader, 500);
    await tester.pumpAndSettle();
    expect(dangerHeader, findsOneWidget);
    expect(find.text('Delete All Data & Reset'), findsOneWidget);
  });

  testWidgets('tapping Delete All Data opens confirmation dialog requiring DELETE', (WidgetTester tester) async {
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

    final deleteTile = find.text('Delete All Data & Reset');
    await tester.scrollUntilVisible(deleteTile, 500);
    await tester.pumpAndSettle();

    expect(deleteTile, findsOneWidget);
    await tester.tap(deleteTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Delete All Data & Reset?'), findsOneWidget);
    final deleteButton = find.widgetWithText(ElevatedButton, 'Delete Everything');
    expect(tester.widget<ElevatedButton>(deleteButton).enabled, isFalse);

    // Enter wrong text
    await tester.enterText(find.byType(TextField), 'del');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(deleteButton).enabled, isFalse);

    // Enter DELETE
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(deleteButton).enabled, isTrue);

    await tester.tap(deleteButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(mockDeletionService.executeFullResetCalled, isTrue);
    expect(find.text('Onboarding Screen'), findsOneWidget);
  });

  testWidgets('v1.0 release: hides pro banner, cloud sync, security section, and pro gates when enableSubscriptions is false',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AppConfig.enableSubscriptions = false;

    await tester.pumpWidget(buildTestableWidget(isPro: false));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Pro'), findsNothing);
    expect(find.text('Prism Pro Active'), findsNothing);
    expect(find.text('SECURITY & SYNC'), findsNothing);
    expect(find.text('Security Trust Center'), findsNothing);
    expect(find.text('Cloud Sync'), findsNothing);
    expect(find.text('Custom Macros'), findsNothing);
    expect(find.text('Custom Templates'), findsNothing);
    expect(find.text('Editorial Palettes'), findsNothing);
  });
}

