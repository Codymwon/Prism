import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/auth/presentation/providers/auth_provider.dart';
import 'package:prism/features/settings/presentation/screens/settings_screen.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// ─── Mocks ────────────────────────────────────────────────────────────────────

class FakeUser extends Fake implements sb.User {
  @override
  final String id = 'test-user-id';
  @override
  final String? email = 'test@example.com';
}

class MockAuthNotifier extends AutoDisposeNotifier<PrismAuthState> implements Auth {
  final sb.User? mockUser;
  bool signOutCalled = false;

  MockAuthNotifier({this.mockUser});

  @override
  PrismAuthState build() {
    return PrismAuthState(user: mockUser);
  }

  @override
  Future<Either<AuthFailure, sb.User>> signUpWithEmail(String email, String password) async =>
      Left(AuthUnknownFailure(''));

  @override
  Future<Either<AuthFailure, sb.User>> loginWithEmail(String email, String password) async =>
      Left(AuthUnknownFailure(''));

  @override
  Future<Either<AuthFailure, sb.User>> loginWithGoogle() async =>
      Left(AuthUnknownFailure(''));

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = const PrismAuthState(user: null);
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
    required MockAuthNotifier mockAuth,
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
          path: '/settings/register',
          builder: (context, state) => const Scaffold(body: Text('Register Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        isProProvider.overrideWith((ref) => isPro),
        authProvider.overrideWith(() => mockAuth),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('displays Try Prism Pro and Sign In to Prism Account when non-Pro and unauthenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthNotifier(mockUser: null);
    await tester.pumpWidget(buildTestableWidget(isPro: false, mockAuth: mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Try Prism Pro'), findsOneWidget);
    expect(find.text('Sign In to Prism Account'), findsOneWidget);
    expect(find.text('Link Prism Account'), findsNothing);
  });

  testWidgets('displays Account and Try Prism Pro when non-Pro and authenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthNotifier(mockUser: FakeUser());
    await tester.pumpWidget(buildTestableWidget(isPro: false, mockAuth: mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Try Prism Pro'), findsOneWidget);
    expect(find.text('Account: test@example.com'), findsOneWidget);
    expect(find.text('Sign In to Prism Account'), findsNothing);
  });

  testWidgets('displays Prism Pro Active and Link Prism Account nudge card when Pro and unauthenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthNotifier(mockUser: null);
    await tester.pumpWidget(buildTestableWidget(isPro: true, mockAuth: mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Prism Pro Active'), findsOneWidget);
    expect(find.text('Link Prism Account'), findsOneWidget);
    expect(find.text('Try Prism Pro'), findsNothing);
  });

  testWidgets('displays Prism Pro Active and Account with Sign Out when Pro and authenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthNotifier(mockUser: FakeUser());
    await tester.pumpWidget(buildTestableWidget(isPro: true, mockAuth: mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Prism Pro Active'), findsOneWidget);
    expect(find.text('Account: test@example.com'), findsOneWidget);

    // Tap to sign out
    await tester.tap(find.text('Account: test@example.com'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(mockAuth.signOutCalled, true);
  });
}

