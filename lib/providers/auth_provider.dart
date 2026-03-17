import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/app_lifecycle_service.dart';
import 'sse_provider.dart';

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
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AuthState());

  // Login
  Future<void> login(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(phone, otp);
      state = AuthState(user: user, isLoading: false);
      
      // Connect to SSE after successful login
      if (user != null) {
        try {
          final lifecycleService = _ref.read(appLifecycleServiceProvider);
          await lifecycleService.onLogin(user.id, user.token);
        } catch (e) {
          print('Auth: SSE connection failed, but login successful: $e');
          // Don't fail login if SSE fails
        }
      }
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
      // Disconnect SSE before logout
      final lifecycleService = _ref.read(appLifecycleServiceProvider);
      lifecycleService.onLogout();
      
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
      
      // Connect to SSE if user was loaded
      if (user != null) {
        try {
          final lifecycleService = _ref.read(appLifecycleServiceProvider);
          await lifecycleService.onLogin(user.id, user.token);
        } catch (e) {
          print('Auth: SSE connection failed on auto-login: $e');
          // Don't fail auto-login if SSE fails
        }
      }
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
  final baseUrl = ref.watch(baseUrlProvider);
  return AuthService(baseUrl: baseUrl);
});

// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
