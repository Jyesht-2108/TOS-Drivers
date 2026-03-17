// Trip service with real API implementation

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';

class TripService {
  final String baseUrl;

  TripService({this.baseUrl = 'http://192.168.1.101:8082'});

  // Get auth token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get user ID from storage
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Start a new trip
  Future<Trip> startTrip(String routeId, TripType tripType) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      final url = Uri.parse('$baseUrl/api/v1/trips/start');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId ?? '',
        },
        body: jsonEncode({
          'route_id': routeId,
          'trip_type': tripType == TripType.PICKUP ? 'PICKUP' : 'DROP',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Trip.fromJson(data);
      } else {
        throw Exception('Failed to start trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: Unable to start trip');
    }
  }

  // End an active trip
  Future<Trip> endTrip(String tripId) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      final url = Uri.parse('$baseUrl/api/v1/trips/end');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId ?? '',
        },
        body: jsonEncode({
          'trip_id': tripId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Trip.fromJson(data);
      } else {
        throw Exception('Failed to end trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: Unable to end trip');
    }
  }

  // Get the currently active trip
  Future<Trip?> getActiveTrip() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      final url = Uri.parse('$baseUrl/api/v1/trips/active');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return Trip.fromJson(data);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null; // No active trip
      } else {
        throw Exception('Failed to get active trip: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting active trip: $e');
      return null;
    }
  }

  // Get all past trips
  Future<List<Trip>> getPastTrips() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      final url = Uri.parse('$baseUrl/api/v1/trips/history');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId ?? '',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Trip.fromJson(json)).toList();
      } else {
        return []; // Return empty list if no history
      }
    } catch (e) {
      print('Error getting past trips: $e');
      return [];
    }
  }
}
