import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../repositories/auth_repository.dart';

/// Provider for AuthController managing reactive authentication state.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Riverpod Notifier managing authentication state without code generation.
class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    // Asynchronously verify existing session on launch
    Future.microtask(() => checkSession());
    return const AuthState(status: AuthStatus.initial);
  }

  /// Verifies whether an existing valid cookie session exists on the device.
  Future<void> checkSession() async {
    if (state.status == AuthStatus.authenticated) return;

    state = state.copyWith(status: AuthStatus.loading);
    final hasSession = await _repository.hasValidSession();

    // Guard: do not overwrite if an active login or explicit error finished while awaiting
    if (state.status == AuthStatus.authenticated || state.status == AuthStatus.error) {
      return;
    }

    if (hasSession) {
      final persistedUser = _repository.getPersistedUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: persistedUser ?? state.user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
    }
  }

  /// Authenticates using email, password, and rememberMe.
  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );

    try {
      final user = await _repository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Logs out of the current session and clears cookies.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Force unauthenticated state (invoked by 401 interceptor).
  void handleUnauthorized() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
