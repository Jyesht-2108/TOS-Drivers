// Authentication state management with Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Auth state class
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Clear error
  AuthState clearError() {
    return AuthState(
      user: user,
      isLoading: isLoading,
      error: null,
    );
  }

  // Clear user (logout)
  AuthState clearUser() {
    return const AuthState(
      user: null,
      isLoading: false,
      error: null,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  // Login
  Future<void> login(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(phone, otp);
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.logout();
      state = state.clearUser();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Load stored user (on app start)
  Future<void> loadStoredUser() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final user = await _authService.loadStoredUser();
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = const AuthState(user: null, isLoading: false);
    }
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
