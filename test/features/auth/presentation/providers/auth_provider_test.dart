import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:prism/features/auth/presentation/providers/auth_provider.dart';
import 'package:prism/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/features/subscription/data/datasources/revenuecat_client_wrapper.dart';

// ─── Fake/Mock Classes ────────────────────────────────────────────────────────

class FakeUser extends Fake implements sb.User {
  @override
  final String id;
  @override
  final String? email;

  FakeUser({required this.id, this.email});
}

class FakeSession extends Fake implements sb.Session {
  @override
  final sb.User user;
  @override
  final String accessToken;

  FakeSession({required this.user, required this.accessToken});
}

class MockGoTrueClient extends Fake implements sb.GoTrueClient {
  sb.User? mockUser;
  sb.Session? mockSession;
  bool signUpCalled = false;
  bool signInCalled = false;
  bool signInWithIdTokenCalled = false;
  bool signOutCalled = false;
  
  final _stateController = StreamController<sb.AuthState>.broadcast();

  @override
  Stream<sb.AuthState> get onAuthStateChange => _stateController.stream;

  @override
  sb.User? get currentUser => mockUser;

  @override
  sb.Session? get currentSession => mockSession;

  @override
  Future<sb.AuthResponse> signUp({
    String? email,
    String? password,
    String? phone,
    String? redirectTo,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    sb.OtpChannel channel = sb.OtpChannel.sms,
    String? captchaToken,
  }) async {
    signUpCalled = true;
    final user = FakeUser(id: 'mock-supabase-id-123', email: email);
    final session = FakeSession(user: user, accessToken: 'mock-token');
    mockUser = user;
    mockSession = session;
    _stateController.add(sb.AuthState(sb.AuthChangeEvent.signedIn, session));
    return sb.AuthResponse(session: session, user: user);
  }

  @override
  Future<sb.AuthResponse> signInWithPassword({
    String? email,
    String? password,
    String? phone,
    String? captchaToken,
  }) async {
    signInCalled = true;
    final user = FakeUser(id: 'mock-supabase-id-123', email: email);
    final session = FakeSession(user: user, accessToken: 'mock-token');
    mockUser = user;
    mockSession = session;
    _stateController.add(sb.AuthState(sb.AuthChangeEvent.signedIn, session));
    return sb.AuthResponse(session: session, user: user);
  }

  @override
  Future<sb.AuthResponse> signInWithIdToken({
    required sb.OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    signInWithIdTokenCalled = true;
    final user = FakeUser(id: 'mock-supabase-google-id', email: 'google@test.com');
    final session = FakeSession(user: user, accessToken: 'mock-google-token');
    mockUser = user;
    mockSession = session;
    _stateController.add(sb.AuthState(sb.AuthChangeEvent.signedIn, session));
    return sb.AuthResponse(session: session, user: user);
  }

  @override
  Future<void> signOut({sb.SignOutScope scope = sb.SignOutScope.local}) async {
    signOutCalled = true;
    mockUser = null;
    mockSession = null;
    _stateController.add(const sb.AuthState(sb.AuthChangeEvent.signedOut, null));
  }
}

class MockSupabaseClient extends Fake implements sb.SupabaseClient {
  final sb.GoTrueClient _auth;
  MockSupabaseClient(this._auth);

  @override
  sb.GoTrueClient get auth => _auth;
}

class MockRevenueCatClientWrapper implements RevenueCatClientWrapper {
  bool configureCalled = false;
  PurchasesConfiguration? lastConfiguration;
  LogLevel? lastLogLevel;
  CustomerInfo? mockCustomerInfo;
  bool isConfiguredValue = false;
  PlatformException? exceptionToThrow;
  Offerings? mockOfferings;
  Package? lastPurchasedPackage;
  String? loggedInUserId;
  bool logInCalled = false;
  bool logOutCalled = false;

  @override
  Future<void> configure(PurchasesConfiguration configuration) async {
    configureCalled = true;
    lastConfiguration = configuration;
    isConfiguredValue = true;
  }

  @override
  Future<void> setLogLevel(LogLevel level) async {
    lastLogLevel = level;
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockCustomerInfo != null) return mockCustomerInfo!;
    throw UnimplementedError();
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockCustomerInfo != null) return mockCustomerInfo!;
    throw UnimplementedError();
  }

  @override
  Future<void> presentPaywall() async {}

  @override
  Future<void> presentPaywallIfNeeded(String entitlement) async {}

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Stream<CustomerInfo> get customerInfoStream => const Stream.empty();

  @override
  Future<bool> isConfigured() async => isConfiguredValue;

  @override
  Future<Offerings> getOfferings() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockOfferings != null) return mockOfferings!;
    throw UnimplementedError();
  }

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    lastPurchasedPackage = package;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockCustomerInfo != null) return mockCustomerInfo!;
    throw UnimplementedError();
  }

  @override
  Future<LogInResult> logIn(String appUserId) async {
    logInCalled = true;
    loggedInUserId = appUserId;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    final customerInfo = mockCustomerInfo ?? FakeCustomerInfo(const {});
    return FakeLogInResult(customerInfo, true);
  }

  @override
  Future<CustomerInfo> logOut() async {
    logOutCalled = true;
    loggedInUserId = null;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mockCustomerInfo ?? FakeCustomerInfo(const {});
  }
}

class FakeLogInResult extends Fake implements LogInResult {
  @override
  final CustomerInfo customerInfo;
  @override
  final bool created;

  FakeLogInResult(this.customerInfo, this.created);
}

class FakeCustomerInfo extends Fake implements CustomerInfo {
  final Map<String, EntitlementInfo> _mockActiveEntitlements;

  FakeCustomerInfo(this._mockActiveEntitlements);

  @override
  EntitlementInfos get entitlements => FakeEntitlementInfos(_mockActiveEntitlements);
}

class FakeEntitlementInfos extends Fake implements EntitlementInfos {
  @override
  final Map<String, EntitlementInfo> active;

  FakeEntitlementInfos(this.active);
}

class MockGoogleSignIn extends Fake implements GoogleSignIn {
  bool signInCalled = false;
  bool signOutCalled = false;
  GoogleSignInAccount? mockAccount;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalled = true;
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalled = true;
    return null;
  }
}

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  final String email;
  @override
  final String id;
  @override
  final String? displayName;

  FakeGoogleSignInAccount({required this.email, required this.id, this.displayName});

  @override
  Future<GoogleSignInAuthentication> get authentication async => FakeGoogleSignInAuthentication();
}

class FakeGoogleSignInAuthentication extends Fake implements GoogleSignInAuthentication {
  @override
  String get idToken => 'mock-google-id-token';
  @override
  String get accessToken => 'mock-google-access-token';
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockGoTrueClient mockAuth;
  late MockSupabaseClient mockSupabase;
  late MockRevenueCatClientWrapper mockRevenueCat;
  late MockGoogleSignIn mockGoogleSignIn;
  late ProviderContainer container;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockSupabase = MockSupabaseClient(mockAuth);
    mockRevenueCat = MockRevenueCatClientWrapper();
    mockGoogleSignIn = MockGoogleSignIn();

    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
        revenueCatClientWrapperProvider.overrideWithValue(mockRevenueCat),
        googleSignInProvider.overrideWithValue(mockGoogleSignIn),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('signUpWithEmail registers in Supabase and calls RevenueCat logIn', () async {
    final authNotifier = container.read(authProvider.notifier);
    
    final result = await authNotifier.signUpWithEmail('test@prism.com', 'password123');

    expect(result.isRight(), true);
    expect(mockAuth.signUpCalled, true);
    expect(mockRevenueCat.logInCalled, true);
    expect(mockRevenueCat.loggedInUserId, 'mock-supabase-id-123');
    
    final state = container.read(authProvider);
    expect(state.user, isNotNull);
    expect(state.user!.id, 'mock-supabase-id-123');
    expect(state.isLoading, false);
  });

  test('loginWithEmail signs in with Supabase and calls RevenueCat logIn', () async {
    final authNotifier = container.read(authProvider.notifier);

    final result = await authNotifier.loginWithEmail('test@prism.com', 'password123');

    expect(result.isRight(), true);
    expect(mockAuth.signInCalled, true);
    expect(mockRevenueCat.logInCalled, true);
    expect(mockRevenueCat.loggedInUserId, 'mock-supabase-id-123');

    final state = container.read(authProvider);
    expect(state.user, isNotNull);
    expect(state.isLoading, false);
  });

  test('loginWithGoogle triggers google authentication, Supabase signin, and RevenueCat logIn', () async {
    final account = FakeGoogleSignInAccount(email: 'google@test.com', id: 'google-id');
    mockGoogleSignIn.mockAccount = account;
    final authNotifier = container.read(authProvider.notifier);

    final result = await authNotifier.loginWithGoogle();

    expect(result.isRight(), true);
    expect(mockGoogleSignIn.signInCalled, true);
    expect(mockAuth.signInWithIdTokenCalled, true);
    expect(mockRevenueCat.logInCalled, true);
    expect(mockRevenueCat.loggedInUserId, 'mock-supabase-google-id');

    final state = container.read(authProvider);
    expect(state.user, isNotNull);
    expect(state.user!.id, 'mock-supabase-google-id');
  });

  test('signOut logs out of all services', () async {
    // Seed initial signed-in state
    await mockAuth.signUp(email: 'test@prism.com', password: 'password123');
    await mockRevenueCat.logIn('mock-supabase-id-123');
    
    final authNotifier = container.read(authProvider.notifier);
    await authNotifier.signOut();

    expect(mockAuth.signOutCalled, true);
    expect(mockRevenueCat.logOutCalled, true);
    expect(mockGoogleSignIn.signOutCalled, true);

    final state = container.read(authProvider);
    expect(state.user, isNull);
  });
}
