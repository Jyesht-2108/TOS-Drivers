// Attendance service with real API implementation

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';
import '../core/constants/app_constants.dart';

class AttendanceService {
  final String baseUrl;

  AttendanceService({this.baseUrl = ApiConfig.baseUrl});

  // Get auth token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetch attendance records for a trip
  /// GET /api/v1/attendance?trip_id={trip_id}
  Future<List<AttendanceRecord>> getAttendanceForTrip(String tripId) async {
    try {
      final token = await _getToken();
      
      // Backend expects query parameter, not path parameter
      final url = Uri.parse('$baseUrl/api/v1/attendance').replace(
        queryParameters: {'trip_id': tripId},
      );
      
      developer.log('AttendanceService: Fetching attendance for trip $tripId from $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token ?? 'mock-token'}',
        },
      ).timeout(AppConstants.apiTimeout);

      developer.log('AttendanceService: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('AttendanceService: Loaded ${data.length} attendance records');
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        developer.log('AttendanceService: Failed to load attendance: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('AttendanceService: Error fetching attendance: $e');
      rethrow;
    }
  }

  /// Mark attendance for a student
  /// POST /api/v1/attendance/mark
  /// Body: { "attendance_id": "uuid", "status": "PRESENT" | "ABSENT" }
  Future<void> markAttendance(
    String attendanceId,
    AttendanceStatus status,
  ) async {
    try {
      final token = await _getToken();
      
      final url = Uri.parse('$baseUrl/api/v1/attendance/mark');
      
      final payload = {
        'attendance_id': attendanceId,
        'status': status.name, // PRESENT or ABSENT
      };
      
      developer.log('AttendanceService: Marking attendance $attendanceId as ${status.name}');
      developer.log('AttendanceService: POST $url with payload: $payload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token ?? 'mock-token'}',
        },
        body: jsonEncode(payload),
      ).timeout(AppConstants.apiTimeout);

      developer.log('AttendanceService: Response status ${response.statusCode}');
      developer.log('AttendanceService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        developer.log('AttendanceService: Attendance marked successfully');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? 'Attendance record not found or locked';
        throw Exception(errorMsg);
      } else {
        throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('AttendanceService: Error marking attendance: $e');
      rethrow;
    }
  }
}
