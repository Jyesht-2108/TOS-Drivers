// Attendance service with real API implementation

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  final String baseUrl;

  AttendanceService({this.baseUrl = 'http://192.168.1.101:8082'});

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

  // Get attendance records for a trip
  Future<List<AttendanceRecord>> getAttendanceForTrip(String tripId) async {
    try {
      final token = await _getToken();
      
      final url = Uri.parse('$baseUrl/api/v1/trips/$tripId/attendance');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: Unable to fetch attendance');
    }
  }

  // Mark attendance for a student
  Future<AttendanceRecord> markAttendance(
    String studentId,
    String tripId,
    AttendanceStatus status,
  ) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      final url = Uri.parse('$baseUrl/api/v1/attendance/mark');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId ?? '',
        },
        body: jsonEncode({
          'student_id': studentId,
          'trip_id': tripId,
          'status': status == AttendanceStatus.PRESENT ? 'PRESENT' : 'ABSENT',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AttendanceRecord.fromJson(data);
      } else {
        throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: Unable to mark attendance');
    }
  }

  // Check if attendance is locked for a student
  Future<bool> isAttendanceLocked(String studentId, String tripId) async {
    try {
      final attendanceList = await getAttendanceForTrip(tripId);
      final record = attendanceList.firstWhere(
        (record) => record.studentId == studentId,
        orElse: () => AttendanceRecord(
          studentId: studentId,
          tripId: tripId,
          status: AttendanceStatus.UNMARKED,
          isLocked: false,
        ),
      );
      return record.isLocked;
    } catch (e) {
      return false;
    }
  }
}
