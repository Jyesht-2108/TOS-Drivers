// Application constants

class ApiConfig {
  // Backend base URL - Go backend on port 8082
  static const String baseUrl = 'http://192.168.1.101:8082';
  
  // API version prefix
  static const String apiPrefix = '/api/v1';
  
  // Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';
  
  // Environment-specific URLs (uncomment as needed)
  
  // For Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8082';
  
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:8082';
  
  // For Physical Device (update with your computer's IP):
  // static const String baseUrl = 'http://192.168.1.101:8082';
}

class AppConstants {
  // App info
  static const String appName = 'TOS Driver';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // GPS tracking
  static const Duration gpsUpdateInterval = Duration(seconds: 30);
  
  // SSE reconnection
  static const Duration sseReconnectDelay = Duration(seconds: 5);
}
