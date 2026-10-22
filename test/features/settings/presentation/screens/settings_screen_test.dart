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

    // Verify Pillar 2: Security & Sync
    expect(find.text('SECURITY & SYNC'), findsOneWidget);
    expect(find.text('Security Trust Center'), findsOneWidget);
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
  });

  testWidgets('tapping Security Trust Center tile navigates to /settings/security', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/security',
          builder: (context, state) => const Scaffold(body: Text('Security Trust Center Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isProProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final securityTile = find.text('Security Trust Center');
    expect(securityTile, findsOneWidget);
    await tester.tap(securityTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Security Trust Center Page'), findsOneWidget);
  });
}

