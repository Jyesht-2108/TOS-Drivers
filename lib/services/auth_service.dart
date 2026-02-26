// Authentication service with mock implementation

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'mock_data_store.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  User? _currentUser;

  // Login with phone and OTP
  Future<User?> login(String phone, String otp) async {
    return await MockDataStore.simulateApiCall(() {
      // Validate OTP
      if (otp != MockDataStore.validOtp) {
        throw Exception('Invalid OTP');
      }

      // Find user by phone number
      final user = MockDataStore.mockUsers.firstWhere(
        (u) => u.phone == phone,
        orElse: () => throw Exception('Invalid phone number'),
      );

      // Store token and user ID in SharedPreferences
      _persistAuthData(user.token, user.id);
      
      _currentUser = user;
      return user;
    });
  }

  // Logout and clear stored token
  Future<void> logout() async {
    return await MockDataStore.simulateApiCall(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      _currentUser = null;
    });
  }

  // Get current authenticated user
  User? getCurrentUser() {
    return _currentUser;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _currentUser != null;
  }

  // Load user from stored token (for app restart)
  Future<User?> loadStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);

    if (token != null && userId != null) {
      // Find user by ID
      try {
        final user = MockDataStore.mockUsers.firstWhere(
          (u) => u.id == userId && u.token == token,
        );
        _currentUser = user;
        return user;
      } catch (e) {
        // User not found, clear invalid data
        await prefs.remove(_tokenKey);
        await prefs.remove(_userIdKey);
        return null;
      }
    }
    return null;
  }

  // Persist authentication data to SharedPreferences
  Future<void> _persistAuthData(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
  }
}
