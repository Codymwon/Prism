import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/settings/presentation/screens/settings_screen.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': '/mock/vaults',
    });
  });

  Widget buildTestableWidget({
    required bool isPro,
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
      ],
    );

    return ProviderScope(
      overrides: [
        isProProvider.overrideWith((ref) => isPro),
      ],
      child: MaterialApp.router(
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

    expect(find.text('Try Prism Pro'), findsOneWidget);
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
    expect(find.text('Try Prism Pro'), findsNothing);
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
}
