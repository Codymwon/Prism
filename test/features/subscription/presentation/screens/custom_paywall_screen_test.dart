import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/subscription/domain/entities/subscription_package.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/features/subscription/presentation/screens/custom_paywall_screen.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  const mockYearly = SubscriptionPackage(
    id: 'yearly_sub',
    identifier: 'prism_pro_yearly',
    title: 'Prism Pro Yearly',
    description: 'Yearly access',
    priceString: '\$29.99',
    price: 29.99,
    currencyCode: 'USD',
    packageType: 'yearly',
  );

  Widget buildTestableWidget({
    List<SubscriptionPackage> packages = const [mockYearly],
    GoRouter? router,
  }) {
    final testRouter = router ??
        GoRouter(
          initialLocation: '/paywall',
          routes: [
            GoRoute(
              path: '/paywall',
              builder: (context, state) => const CustomPaywallScreen(),
            ),
            GoRoute(
              path: '/settings/terms',
              builder: (context, state) => const Scaffold(body: Text('Terms Screen')),
            ),
            GoRoute(
              path: '/settings/privacy',
              builder: (context, state) => const Scaffold(body: Text('Privacy Screen')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        isProProvider.overrideWith((ref) => false),
        availablePackagesProvider.overrideWith((ref) async => packages),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: testRouter,
      ),
    );
  }

  testWidgets('renders dynamic recurring disclaimer and legal footer links', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify dynamic disclaimer containing price and period
    expect(
      find.text(
        'Prism Pro renews automatically (\$29.99/year) until cancelled. Payment is charged to your account at confirmation. Cancel anytime in your account settings at least 24 hours before renewal to prevent charges.',
      ),
      findsOneWidget,
    );

    // Verify legal links
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Manage Subscription'), findsOneWidget);

    // Tap Terms of Service link
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();
    expect(find.text('Terms Screen'), findsOneWidget);
  });
}
