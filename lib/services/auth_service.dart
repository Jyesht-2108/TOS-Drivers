// Authentication service with real API implementation

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userPhoneKey = 'user_phone';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  User? _currentUser;
  final String baseUrl;

  AuthService({this.baseUrl = ApiConfig.baseUrl});

  // Login with phone and OTP (Go backend)
  Future<User?> login(String phone, String otp) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/auth/login');
      print('Auth: Attempting login to $url with phone: $phone');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
        }),
      ).timeout(
        AppConstants.apiTimeout,
        onTimeout: () {
          throw Exception('Connection timeout - Check if backend is accessible at ${ApiConfig.baseUrl}');
        },
      );

      print('Auth: Response status: ${response.statusCode}');
      print('Auth: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final apiResponse = jsonDecode(response.body);
        
        // Go backend returns: { "token": "...", "user": {...} }
        final token = apiResponse['token'] as String;
        final userData = apiResponse['user'];
        
        final user = User(
          id: userData['id'].toString(),
          phone: userData['phone'] as String? ?? '',
          role: UserRole.DRIVER,
          token: token,
          name: userData['name'] as String?,
          email: userData['email'] as String?,
        );

        // Store user data
        await _persistAuthData(
          token,
          user.id,
          user.phone,
          user.name ?? 'Driver',
          user.email ?? '',
        );
        
        _currentUser = user;
        print('Auth: Login successful for ${user.name}');
        return user;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid phone number or user not found');
      } else if (response.statusCode == 400) {
        throw Exception('Bad request - Check phone number format');
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('Auth: Socket error during login: $e');
      throw Exception('Cannot connect to server at ${ApiConfig.baseUrl}. Please check:\n'
          '1. Your phone is on the same WiFi network\n'
          '2. Backend is running on port 8082\n'
          '3. IP address is correct (${ApiConfig.baseUrl})');
    } on http.ClientException catch (e) {
      print('Auth: Client error during login: $e');
      throw Exception('Network connection failed. Please check:\n'
          '1. Your internet connection\n'
          '2. Backend server is accessible\n'
          '3. Firewall is not blocking port 8082');
    } on FormatException catch (e) {
      print('Auth: Invalid response format: $e');
      throw Exception('Invalid response from server. Backend may be misconfigured.');
    } catch (e) {
      print('Auth: Error during login: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: Unable to connect to server at ${ApiConfig.baseUrl}');
    }
  }

  // Logout and clear stored token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    _currentUser = null;
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
    final phone = prefs.getString(_userPhoneKey);
    final name = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);

    if (token != null && userId != null) {
      final user = User(
        id: userId,
        phone: phone ?? '',
        role: UserRole.DRIVER,
        token: token,
        name: name,
        email: email,
      );
      _currentUser = user;
      return user;
    }
    return null;
  }

  // Persist authentication data to SharedPreferences
  Future<void> _persistAuthData(
    String token,
    String userId,
    String phone,
    String name,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userPhoneKey, phone);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }
}
