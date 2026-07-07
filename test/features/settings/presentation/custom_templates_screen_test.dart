import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prism/core/services/template_service.dart';
import 'package:prism/features/settings/presentation/screens/custom_templates_screen.dart';
import 'package:prism/features/subscription/domain/entities/subscription_status.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/features/subscription/presentation/screens/custom_paywall_screen.dart';

class FakeTemplateServiceRef implements TemplateServiceRef {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeTemplateService extends TemplateService {
  final List<String> templates = ['gratitude', 'daily-plan'];
  final List<({String name, String content})> writes = [];
  final List<String> deletes = [];

  FakeTemplateService() : super(FakeTemplateServiceRef());

  @override
  Future<Either<TemplateFailure, List<String>>> listTemplates() async {
    return Right(List.from(templates));
  }

  @override
  Future<Either<TemplateFailure, Unit>> writeTemplate(String name, String content) async {
    writes.add((name: name, content: content));
    final slug = name.toLowerCase().replaceAll(' ', '-');
    if (!templates.contains(slug)) {
      templates.add(slug);
    }
    return const Right(unit);
  }

  @override
  Future<Either<TemplateFailure, Unit>> deleteTemplate(String name) async {
    deletes.add(name);
    templates.remove(name);
    return const Right(unit);
  }
}

Widget _buildApp({
  required bool isPro,
  required FakeTemplateService fakeTemplateService,
  GoRouter? customRouter,
}) {
  final container = ProviderContainer(
    overrides: [
      subscriptionStatusProvider.overrideWith(
        (ref) => Stream.value(SubscriptionStatus(
          isPro: isPro,
          expirationDate: null,
          activeEntitlements: const {},
        )),
      ),
      templateServiceProvider.overrideWith((ref) => fakeTemplateService),
    ],
  );

  final router = customRouter ??
      GoRouter(
        initialLocation: '/settings/custom-templates',
        routes: [
          GoRoute(
            path: '/settings/custom-templates',
            builder: (context, state) => const CustomTemplatesScreen(),
          ),
          GoRoute(
            path: '/settings/paywall',
            builder: (context, state) => const CustomPaywallScreen(),
          ),
          GoRoute(
            path: '/editor/:id',
            builder: (context, state) => const Scaffold(body: Text('Editor Screen')),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('redirects non-Pro users to the paywall', (tester) async {
    final fakeService = FakeTemplateService();
    await tester.pumpWidget(_buildApp(isPro: false, fakeTemplateService: fakeService));
    await tester.pumpAndSettle();

    expect(find.byType(CustomPaywallScreen), findsOneWidget);
    expect(find.byType(CustomTemplatesScreen), findsNothing);
  });

  testWidgets('loads and renders list of templates for Pro users', (tester) async {
    final fakeService = FakeTemplateService();
    await tester.pumpWidget(_buildApp(isPro: true, fakeTemplateService: fakeService));
    await tester.pumpAndSettle();

    expect(find.byType(CustomTemplatesScreen), findsOneWidget);
    expect(find.text('Custom Templates'), findsOneWidget);
    expect(find.text('Gratitude'), findsOneWidget);
    expect(find.text('Daily Plan'), findsOneWidget);
  });

  testWidgets('clicking delete template prompts confirmation and deletes it', (tester) async {
    final fakeService = FakeTemplateService();
    await tester.pumpWidget(_buildApp(isPro: true, fakeTemplateService: fakeService));
    await tester.pumpAndSettle();

    // Find the delete button for "Gratitude"
    final deleteButton = find.descendant(
      of: find.widgetWithText(Container, 'Gratitude'),
      matching: find.byIcon(Icons.delete_outline_rounded),
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm dialog is shown
    expect(find.text('Delete Template'), findsOneWidget);
    expect(find.text('Are you sure you want to permanently delete the template "Gratitude"? This action cannot be undone.'), findsOneWidget);

    // Tap Cancel first to make sure it doesn't delete
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fakeService.deletes, isEmpty);

    // Tap Delete button to open dialog again
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Tap Delete in dialog to confirm deletion
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(fakeService.deletes, contains('gratitude'));
    expect(find.text('Gratitude'), findsNothing); // Should be removed from list
  });

  testWidgets('creating a template writes it and navigates to the editor', (tester) async {
    final fakeService = FakeTemplateService();
    await tester.pumpWidget(_buildApp(isPro: true, fakeTemplateService: fakeService));
    await tester.pumpAndSettle();

    // Tap FAB to create a template
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Dialog should show up
    expect(find.text('Create Template'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(TextField), 'Meeting Notes');
    await tester.pumpAndSettle();

    // Tap Create
    await tester.tap(find.widgetWithText(TextButton, 'Create'));
    await tester.pumpAndSettle();

    // Verify it saved
    expect(fakeService.writes.length, 1);
    expect(fakeService.writes.first.name, 'Meeting Notes');
    expect(fakeService.writes.first.content, contains('title: "Meeting Notes"'));

    // Verify it pushed to editor with path parameters
    expect(find.text('Editor Screen'), findsOneWidget);
  });
}
