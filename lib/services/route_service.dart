// Route service with real API implementation

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route.dart';
import '../models/student.dart';
import '../core/constants/app_constants.dart';

class RouteService {
  final String baseUrl;

  RouteService({this.baseUrl = ApiConfig.baseUrl});

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

  // Get routes assigned to the logged-in driver
  Future<List<Route>> getAssignedRoutes(String driverId) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      print('RouteService: Fetching routes for user: $userId');
      print('RouteService: URL: $baseUrl/api/v1/routes');
      
      final url = Uri.parse('$baseUrl/api/v1/routes');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId ?? '',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - Check if backend is accessible');
        },
      );

      print('RouteService: Response status: ${response.statusCode}');
      print('RouteService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('RouteService: Found ${data.length} routes');
        
        // Parse each route with error handling
        final List<Route> routes = [];
        for (var routeJson in data) {
          try {
            final route = Route.fromJson(routeJson as Map<String, dynamic>);
            routes.add(route);
          } catch (e) {
            print('RouteService: Error parsing route: $e');
            print('RouteService: Route JSON: $routeJson');
            // Continue with other routes
          }
        }
        
        print('RouteService: Successfully parsed ${routes.length} routes');
        return routes;
      } else {
        throw Exception('Failed to load routes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('RouteService: Error - $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  // Get a specific route by ID
  Future<Route?> getRouteById(String routeId) async {
    try {
      final token = await _getToken();
      
      final url = Uri.parse('$baseUrl/api/v1/routes/$routeId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Route.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get students for a specific route
  Future<List<Student>> getStudentsByRoute(String routeId) async {
    try {
      final token = await _getToken();
      
      final url = Uri.parse('$baseUrl/api/v1/routes/$routeId/students');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: Unable to fetch students');
    }
  }
}
