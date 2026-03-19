import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GpsService {
  final String baseUrl;
  Timer? _locationTimer;
  bool _isTracking = false;
  String? _currentTripId;
  bool _hasLocationPermission = false;

  GpsService({required this.baseUrl});

  // Request location permissions (called on login or route view)
  Future<bool> requestLocationPermissions() async {
    print('GPS: Requesting location permissions...');
    
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('GPS: Location services are disabled');
      _hasLocationPermission = false;
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('GPS: Location permissions denied by user');
        _hasLocationPermission = false;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('GPS: Location permissions permanently denied');
      _hasLocationPermission = false;
      return false;
    }

    print('GPS: Location permission granted');
    _hasLocationPermission = true;
    return true;
  }

  // Check if location permissions are granted
  bool get hasLocationPermission => _hasLocationPermission;

  // Start GPS streaming for an ACTIVE trip (15-second interval)
  Future<void> startGpsStreaming(String tripId) async {
    if (_isTracking) {
      print('GPS: Already streaming, stopping previous session');
      await stopGpsStreaming();
    }

    _currentTripId = tripId;
    _isTracking = true;

    print('GPS: Starting GPS streaming for trip: $tripId (15-second interval)');

    // Start the 15-second GPS streaming loop
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _streamGpsUpdate();
    });

    // Send initial GPS update immediately
    await _streamGpsUpdate();
  }

  // Stop GPS streaming (called when trip ends)
  Future<void> stopGpsStreaming() async {
    print('GPS: Stopping GPS streaming and cleaning up');
    _isTracking = false;
    _currentTripId = null;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // Check if currently streaming GPS
  bool get isStreaming => _isTracking;

  // Get current trip ID
  String? get currentTripId => _currentTripId;

  // Stream GPS update to backend (15-second loop)
  Future<void> _streamGpsUpdate() async {
    if (!_isTracking || _currentTripId == null) {
      print('GPS: Skipping update - not tracking or no trip ID');
      return;
    }

    if (!_hasLocationPermission) {
      print('GPS: Skipping update - no location permission');
      return;
    }

    try {
      // Get current device coordinates
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Prepare the exact JSON structure as required by PRD
      final gpsData = {
        'trip_id': _currentTripId!,
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy_m': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('GPS: Streaming update - Lat: ${position.latitude}, Lng: ${position.longitude}, Accuracy: ${position.accuracy}m');

      // Execute POST /api/v1/location/update request (backend endpoint)
      final url = Uri.parse('$baseUrl/api/v1/location/update');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer mock-token', // TODO: Use real token from auth
        },
        body: jsonEncode(gpsData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('GPS streaming timeout');
        },
      );

      if (response.statusCode == 200) {
        print('GPS: Stream update successful - Trip: $_currentTripId');
      } else {
        print('GPS: Stream update failed - Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // Basic error handling - don't crash, just log and continue
      print('GPS: Stream update error: $e');
      print('GPS: Will retry on next 15-second tick');
      // Continue the loop - don't stop streaming on network errors
    }
  }

  // Legacy method for backward compatibility (30-second updates)
  Future<void> startTracking(String tripId) async {
    print('GPS: Legacy startTracking called, using new GPS streaming');
    await startGpsStreaming(tripId);
  }

  // Legacy method for backward compatibility
  Future<void> stopTracking() async {
    print('GPS: Legacy stopTracking called, using new GPS streaming');
    await stopGpsStreaming();
  }

  // Check if currently tracking (legacy compatibility)
  bool get isTracking => _isTracking;

  // Dispose resources and cleanup
  void dispose() {
    print('GPS: Disposing GPS service');
    stopGpsStreaming();
  }
}
