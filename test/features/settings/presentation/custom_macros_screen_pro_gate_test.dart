import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prism/features/settings/presentation/screens/custom_macros_screen.dart';
import 'package:prism/features/subscription/domain/entities/subscription_status.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/features/subscription/presentation/screens/custom_paywall_screen.dart';

Widget _buildApp({required bool isPro}) {
  final container = ProviderContainer(
    overrides: [
      // Override the source stream so isProProvider derives the desired value.
      subscriptionStatusProvider.overrideWith(
        (ref) => Stream.value(SubscriptionStatus(
          isPro: isPro,
          expirationDate: null,
          activeEntitlements: const {},
        )),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: '/settings/custom-macros',
    routes: [
      GoRoute(
        path: '/settings/custom-macros',
        builder: (context, state) => const CustomMacrosScreen(),
      ),
      GoRoute(
        path: '/settings/paywall',
        builder: (context, state) => const CustomPaywallScreen(),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,routerConfig: router),
  );
}

void main() {
  // customMacrosProvider loads from SharedPreferences on construction.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('redirects non-Pro users to the paywall', (tester) async {
    await tester.pumpWidget(_buildApp(isPro: false));
    await tester.pumpAndSettle();

    // Non-Pro: the runtime guard in initState should have redirected.
    expect(find.byType(CustomPaywallScreen), findsOneWidget);
    expect(find.byType(CustomMacrosScreen), findsNothing);
  });

  testWidgets('shows the macros editor for Pro users', (tester) async {
    await tester.pumpWidget(_buildApp(isPro: true));
    await tester.pumpAndSettle();

    // Pro: stays on the macros screen and renders its heading.
    expect(find.byType(CustomMacrosScreen), findsOneWidget);
    expect(find.text('Quick Macros'), findsOneWidget);
  });
}
