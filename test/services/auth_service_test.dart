// Property-based tests for AuthService

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tos_driver_app/models/user.dart';
import 'package:tos_driver_app/services/auth_service.dart';
import 'package:tos_driver_app/services/mock_data_store.dart';
import 'dart:math';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Property Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    // Feature: tos-driver-app, Property 1: Valid credentials grant access
    // Validates: Requirements 1.1
    test('Property 1: Valid credentials grant access - for any valid phone and OTP, authentication should succeed', () async {
      // Test with all mock users to verify the property holds for all valid credentials
      for (final mockUser in MockDataStore.mockUsers) {
        // Setup fresh SharedPreferences for each iteration
        SharedPreferences.setMockInitialValues({});
        final authService = AuthService();
        
        final validPhone = mockUser.phone;
        final validOtp = MockDataStore.validOtp;
        
        // Property: For any valid phone number and OTP combination in the mock data,
        // authentication should succeed and return a User object
        final result = await authService.login(validPhone, validOtp);
        
        expect(result, isNotNull, reason: 'Login should return a user for valid credentials (phone: $validPhone)');
        expect(result, isA<User>(), reason: 'Result should be a User object');
        expect(result!.phone, equals(validPhone), reason: 'Returned user should have the correct phone number');
        expect(result.role, equals(UserRole.DRIVER), reason: 'User role should be DRIVER');
        expect(result.token, isNotEmpty, reason: 'User should have a token');
      }
    });

    // Feature: tos-driver-app, Property 2: Authentication token persistence
    // Validates: Requirements 1.2
    test('Property 2: Authentication token persistence - for any successful authentication, token should be stored and retrievable', () async {
      // Test with all mock users to verify the property holds for all valid credentials
      for (final mockUser in MockDataStore.mockUsers) {
        // Setup fresh SharedPreferences for each iteration
        SharedPreferences.setMockInitialValues({});
        final authService = AuthService();
        
        final validPhone = mockUser.phone;
        final validOtp = MockDataStore.validOtp;
        
        // Property: For any successful authentication, a token should be stored locally
        // and retrievable for subsequent requests
        final loginResult = await authService.login(validPhone, validOtp);
        expect(loginResult, isNotNull, reason: 'Login should succeed (phone: $validPhone)');
        
        // Verify token is persisted by creating a new service instance and loading stored user
        final newAuthService = AuthService();
        final storedUser = await newAuthService.loadStoredUser();
        
        expect(storedUser, isNotNull, reason: 'Stored user should be retrievable (phone: $validPhone)');
        expect(storedUser!.id, equals(loginResult!.id), reason: 'Stored user ID should match logged in user');
        expect(storedUser.token, equals(loginResult.token), reason: 'Stored token should match logged in user token');
        expect(storedUser.phone, equals(loginResult.phone), reason: 'Stored phone should match logged in user phone');
      }
    });

    // Feature: tos-driver-app, Property 4: Invalid credentials error handling
    // Validates: Requirements 1.4
    test('Property 4: Invalid credentials error handling - for any invalid credentials, authentication should fail with error', () async {
      final random = Random();
      
      // Test invalid OTP with valid phones
      for (final mockUser in MockDataStore.mockUsers) {
        SharedPreferences.setMockInitialValues({});
        final authService = AuthService();
        
        final validPhone = mockUser.phone;
        final invalidOtp = '${random.nextInt(900000) + 100000}';
        
        // Skip if we accidentally generated the valid OTP
        if (invalidOtp == MockDataStore.validOtp) continue;
        
        // Property: For any invalid OTP, authentication should fail and throw an exception
        expect(
          () async => await authService.login(validPhone, invalidOtp),
          throwsException,
          reason: 'Login with invalid OTP should throw an exception (phone: $validPhone, otp: $invalidOtp)',
        );
        
        // Verify authentication state is unchanged
        expect(authService.isAuthenticated(), isFalse, reason: 'User should not be authenticated after failed login');
        expect(authService.getCurrentUser(), isNull, reason: 'Current user should be null after failed login');
      }
      
      // Test invalid phone numbers with valid OTP
      for (int i = 0; i < 10; i++) {
        SharedPreferences.setMockInitialValues({});
        final authService = AuthService();
        
        // Generate a phone number that doesn't exist in mock data
        String invalidPhone;
        int attempts = 0;
        do {
          invalidPhone = '${8000000000 + random.nextInt(1000000000)}';
          attempts++;
          if (attempts > 20) break;
        } while (MockDataStore.mockUsers.any((u) => u.phone == invalidPhone));
        
        final validOtp = MockDataStore.validOtp;
        
        // Property: For any invalid phone number, authentication should fail and throw an exception
        expect(
          () async => await authService.login(invalidPhone, validOtp),
          throwsException,
          reason: 'Login with invalid phone should throw an exception (phone: $invalidPhone)',
        );
        
        // Verify authentication state is unchanged
        expect(authService.isAuthenticated(), isFalse, reason: 'User should not be authenticated after failed login');
        expect(authService.getCurrentUser(), isNull, reason: 'Current user should be null after failed login');
      }
    });
  });
}
