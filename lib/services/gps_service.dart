import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Service for GPS tracking and sending location updates to server
class GpsService {
  Timer? _gpsTimer;
  final String baseUrl;
  String? _authToken;
  bool _isTracking = false;
  
  // Callbacks
  Function(Position)? onLocationUpdate;
  Function(String)? onError;
  
  bool get isTracking => _isTracking;
  
  GpsService({required this.baseUrl});
  
  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError?.call('Location services are disabled');
      return false;
    }
    
    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError?.call('Location permissions are denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      onError?.call('Location permissions are permanently denied');
      return false;
    }
    
    return true;
  }
  
  /// Start sending GPS updates every 30 seconds
  Future<void> startTracking(String tripId, String driverId, String token) async {
    if (_isTracking) {
      print('GPS: Already tracking');
      return;
    }
    
    // Check permissions first
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      return;
    }
    
    _authToken = token;
    _isTracking = true;
    
    print('GPS: Started tracking for trip: $tripId');
    
    // Send first update immediately
    _sendUpdate(tripId, driverId);
    
    // Then send every 30 seconds
    _gpsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendUpdate(tripId, driverId);
    });
  }
  
  Future<void> _sendUpdate(String tripId, String driverId) async {
    try {
      final position = await _getCurrentPosition();
      await _sendGpsUpdate(tripId, driverId, position);
      onLocationUpdate?.call(position);
    } catch (e) {
      print('GPS: Error sending update: $e');
      onError?.call('Failed to send GPS update: $e');
    }
  }
  
  /// Get current GPS position
  Future<Position> _getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
  
  /// Send GPS update to server via REST API
  Future<void> _sendGpsUpdate(
    String tripId,
    String driverId,
    Position position,
  ) async {
    final url = Uri.parse('$baseUrl/api/v1/location/update');
    
    final body = {
      'trip_id': tripId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'heading': position.heading,
      'accuracy': position.accuracy,
    };
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        print('GPS: Update sent successfully - Lat: ${position.latitude}, Lng: ${position.longitude}');
      } else {
        print('GPS: Failed to send update: ${response.statusCode} - ${response.body}');
        onError?.call('GPS update failed: ${response.statusCode}');
      }
    } catch (e) {
      print('GPS: Network error: $e');
      // Don't throw - will retry in 30 seconds
      onError?.call('Network error: $e');
    }
  }
  
  /// Stop sending GPS updates
  void stopTracking() {
    if (!_isTracking) {
      return;
    }
    
    print('GPS: Stopped tracking');
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _isTracking = false;
    _authToken = null;
  }
  
  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
