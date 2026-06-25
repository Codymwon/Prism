import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

part 'auth_provider.g.dart';

// Providers for dependencies so they can be overridden in tests
final supabaseClientProvider = Provider<sb.SupabaseClient>((ref) => sb.Supabase.instance.client);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn(
  clientId: '5125181029-5v2u33d9ah7l03q9ufg2cur4rm8uhkv6.apps.googleusercontent.com',
  serverClientId: '5125181029-5v2u33d9ah7l03q9ufg2cur4rm8uhkv6.apps.googleusercontent.com',
));

final supabaseInitializedProvider = Provider<bool>((ref) {
  try {
    ref.watch(supabaseClientProvider);
    return true;
  } catch (_) {
    return false;
  }
});


sealed class AuthFailure {
  final String message;
  const AuthFailure(this.message);
}
class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure(super.message);
}
class AuthInvalidCredentialsFailure extends AuthFailure {
  const AuthInvalidCredentialsFailure(super.message);
}
class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure(super.message);
}

class PrismAuthState {
  final sb.User? user;
  final bool isLoading;
  final AuthFailure? failure;

  const PrismAuthState({this.user, this.isLoading = false, this.failure});
}

@riverpod
class Auth extends _$Auth {
  @override
  PrismAuthState build() {
    final isInitialized = ref.watch(supabaseInitializedProvider);
    if (!isInitialized) {
      return const PrismAuthState(user: null);
    }

    final client = ref.watch(supabaseClientProvider);
    
    // Listen to Supabase auth state changes and reactively update the state
    final sub = client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = PrismAuthState(user: session?.user);
      if (session != null) {
        // Link to RevenueCat when signed in
        final clientWrapper = ref.read(revenueCatClientWrapperProvider);
        clientWrapper.logIn(session.user.id);
      }
    });

    ref.onDispose(() {
      sub.cancel();
    });

    return PrismAuthState(user: client.auth.currentUser);
  }


  Future<Either<AuthFailure, sb.User>> signUpWithEmail(String email, String password) async {
    if (!ref.read(supabaseInitializedProvider)) {
      return const Left(AuthUnknownFailure('Supabase is not configured.'));
    }
    state = PrismAuthState(user: state.user, isLoading: true);
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client.auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) {
        state = const PrismAuthState(failure: AuthUnknownFailure('Sign up failed'));
        return const Left(AuthUnknownFailure('Sign up failed'));
      }
      
      // Link purchases immediately
      final clientWrapper = ref.read(revenueCatClientWrapperProvider);
      await clientWrapper.logIn(user.id);
      
      state = PrismAuthState(user: user);
      return Right(user);
    } on sb.AuthException catch (e) {
      final failure = _mapAuthException(e);
      state = PrismAuthState(failure: failure);
      return Left(failure);
    } catch (e) {
      final failure = AuthUnknownFailure(e.toString());
      state = PrismAuthState(failure: failure);
      return Left(failure);
    }
  }

  Future<Either<AuthFailure, sb.User>> loginWithEmail(String email, String password) async {
    if (!ref.read(supabaseInitializedProvider)) {
      return const Left(AuthUnknownFailure('Supabase is not configured.'));
    }
    state = PrismAuthState(user: state.user, isLoading: true);
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client.auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) {
        state = const PrismAuthState(failure: AuthUnknownFailure('Login failed'));
        return const Left(AuthUnknownFailure('Login failed'));
      }

      // Link purchases immediately
      final clientWrapper = ref.read(revenueCatClientWrapperProvider);
      await clientWrapper.logIn(user.id);

      state = PrismAuthState(user: user);
      return Right(user);
    } on sb.AuthException catch (e) {
      final failure = _mapAuthException(e);
      state = PrismAuthState(failure: failure);
      return Left(failure);
    } catch (e) {
      final failure = AuthUnknownFailure(e.toString());
      state = PrismAuthState(failure: failure);
      return Left(failure);
    }
  }

  Future<Either<AuthFailure, sb.User>> loginWithGoogle() async {
    if (!ref.read(supabaseInitializedProvider)) {
      return const Left(AuthUnknownFailure('Supabase is not configured.'));
    }
    state = PrismAuthState(user: state.user, isLoading: true);
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = const PrismAuthState(failure: AuthUnknownFailure('Google sign in cancelled'));
        return const Left(AuthUnknownFailure('Google sign in cancelled'));
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        state = const PrismAuthState(failure: AuthUnknownFailure('Missing Google ID Token'));
        return const Left(AuthUnknownFailure('Missing Google ID Token'));
      }

      final client = ref.read(supabaseClientProvider);
      final response = await client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        state = const PrismAuthState(failure: AuthUnknownFailure('Supabase sign in failed'));
        return const Left(AuthUnknownFailure('Supabase sign in failed'));
      }

      // Link purchases immediately
      final clientWrapper = ref.read(revenueCatClientWrapperProvider);
      await clientWrapper.logIn(user.id);

      state = PrismAuthState(user: user);
      return Right(user);
    } on sb.AuthException catch (e) {
      final failure = _mapAuthException(e);
      state = PrismAuthState(failure: failure);
      return Left(failure);
    } catch (e) {
      final failure = AuthUnknownFailure(e.toString());
      state = PrismAuthState(failure: failure);
      return Left(failure);
    }
  }

  Future<void> signOut() async {
    if (!ref.read(supabaseInitializedProvider)) {
      return;
    }
    state = const PrismAuthState(isLoading: true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();

      // Sign out of Google Sign-in if active
      final googleSignIn = ref.read(googleSignInProvider);
      await googleSignIn.signOut();

      // Log out of RevenueCat
      final clientWrapper = ref.read(revenueCatClientWrapperProvider);
      await clientWrapper.logOut();

      state = const PrismAuthState(user: null);
    } catch (e) {
      state = PrismAuthState(failure: AuthUnknownFailure(e.toString()));
    }
  }

  AuthFailure _mapAuthException(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid credentials') || msg.contains('incorrect password') || msg.contains('no user found')) {
      return AuthInvalidCredentialsFailure(e.message);
    } else if (msg.contains('network') || msg.contains('connection')) {
      return AuthNetworkFailure(e.message);
    }
    return AuthUnknownFailure(e.message);
  }
}
