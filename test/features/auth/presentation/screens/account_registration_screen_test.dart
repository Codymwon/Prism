import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:prism/features/auth/presentation/screens/account_registration_screen.dart';
import 'package:prism/features/auth/presentation/providers/auth_provider.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class FakeUser extends Fake implements sb.User {
  @override
  final String id = 'test-id';
  @override
  final String? email = 'test@prism.com';
}

class MockAuthNotifier extends AutoDisposeNotifier<PrismAuthState> implements Auth {
  bool signUpCalled = false;
  bool loginCalled = false;
  bool loginWithGoogleCalled = false;
  bool signOutCalled = false;
  
  String? lastEmail;
  String? lastPassword;

  @override
  PrismAuthState build() {
    return const PrismAuthState();
  }

  @override
  Future<Either<AuthFailure, sb.User>> signUpWithEmail(String email, String password) async {
    signUpCalled = true;
    lastEmail = email;
    lastPassword = password;
    state = PrismAuthState(user: FakeUser());
    return Right(FakeUser());
  }

  @override
  Future<Either<AuthFailure, sb.User>> loginWithEmail(String email, String password) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    state = PrismAuthState(user: FakeUser());
    return Right(FakeUser());
  }

  @override
  Future<Either<AuthFailure, sb.User>> loginWithGoogle() async {
    loginWithGoogleCalled = true;
    state = PrismAuthState(user: FakeUser());
    return Right(FakeUser());
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = const PrismAuthState(user: null);
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  Widget buildTestableWidget({required Widget child}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: '/notes',
          builder: (context, state) => const Scaffold(body: Text('Notes')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => mockAuthNotifier),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders registration mode with Skip button', (WidgetTester tester) async {
    bool skipClicked = false;

    await tester.pumpWidget(
      buildTestableWidget(
        child: AccountRegistrationScreen(
          isRegisterMode: true,
          onSkip: () => skipClicked = true,
        ),
      ),
    );

    // Verify Title
    expect(find.text('Create Prism Account'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    
    // Verify inputs and buttons
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Tap skip
    await tester.tap(find.text('Skip for now'));
    await tester.pump();
    expect(skipClicked, true);
  });

  testWidgets('renders login mode without Skip button', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: const AccountRegistrationScreen(
          isRegisterMode: false,
        ),
      ),
    );

    expect(find.text('Sign In to Prism'), findsOneWidget);
    expect(find.text('Skip for now'), findsNothing);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('submitting form triggers signUpWithEmail in registration mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: const AccountRegistrationScreen(
          isRegisterMode: true,
        ),
      ),
    );

    // Fill fields
    await tester.enterText(find.byType(TextField).at(0), 'test@prism.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();

    // Tap Register
    await tester.tap(find.text('Register'), warnIfMissed: false);
    await tester.pump();

    expect(mockAuthNotifier.signUpCalled, true);
    expect(mockAuthNotifier.lastEmail, 'test@prism.com');
    expect(mockAuthNotifier.lastPassword, 'password123');
  });

  testWidgets('submitting form triggers loginWithEmail in login mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: const AccountRegistrationScreen(
          isRegisterMode: false,
        ),
      ),
    );

    // Fill fields
    await tester.enterText(find.byType(TextField).at(0), 'test@prism.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();

    // Tap Sign In
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump();

    expect(mockAuthNotifier.loginCalled, true);
    expect(mockAuthNotifier.lastEmail, 'test@prism.com');
    expect(mockAuthNotifier.lastPassword, 'password123');
  });

  testWidgets('tapping Google button triggers loginWithGoogle', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: const AccountRegistrationScreen(
          isRegisterMode: true,
        ),
      ),
    );

    await tester.tap(find.text('Continue with Google'), warnIfMissed: false);
    await tester.pump();

    expect(mockAuthNotifier.loginWithGoogleCalled, true);
  });
}
