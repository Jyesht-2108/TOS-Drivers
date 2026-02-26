// Attendance service with mock implementation

import '../models/attendance_record.dart';
import '../models/student.dart';
import 'mock_data_store.dart';

class AttendanceService {
  // In-memory storage for attendance records
  final Map<String, List<AttendanceRecord>> _attendanceByTrip = {};

  // Initialize attendance records for a trip
  void initializeAttendanceForTrip(String tripId, List<Student> students) {
    if (_attendanceByTrip.containsKey(tripId)) {
      return; // Already initialized
    }

    _attendanceByTrip[tripId] = students.map((student) {
      return AttendanceRecord(
        studentId: student.id,
        tripId: tripId,
        status: AttendanceStatus.UNMARKED,
        isLocked: false,
      );
    }).toList();
  }

  // Get attendance records for a trip
  Future<List<AttendanceRecord>> getAttendanceForTrip(String tripId) async {
    return await MockDataStore.simulateApiCall(() {
      return _attendanceByTrip[tripId] ?? [];
    });
  }

  // Mark attendance for a student
  Future<AttendanceRecord> markAttendance(
    String studentId,
    String tripId,
    AttendanceStatus status,
  ) async {
    return await MockDataStore.simulateApiCall(() {
      final attendanceList = _attendanceByTrip[tripId];
      
      if (attendanceList == null) {
        throw Exception('No attendance records found for this trip');
      }

      final recordIndex = attendanceList.indexWhere(
        (record) => record.studentId == studentId,
      );

      if (recordIndex == -1) {
        throw Exception('Student not found in this trip');
      }

      final existingRecord = attendanceList[recordIndex];

      if (existingRecord.isLocked) {
        throw Exception('Attendance is already locked for this student');
      }

      // Create updated record with locked status
      final updatedRecord = AttendanceRecord(
        studentId: studentId,
        tripId: tripId,
        status: status,
        isLocked: true,
        markedAt: DateTime.now(),
      );

      attendanceList[recordIndex] = updatedRecord;
      return updatedRecord;
    });
  }

  // Check if attendance is locked for a student
  bool isAttendanceLocked(String studentId, String tripId) {
    final attendanceList = _attendanceByTrip[tripId];
    
    if (attendanceList == null) {
      return false;
    }

    try {
      final record = attendanceList.firstWhere(
        (record) => record.studentId == studentId,
      );
      return record.isLocked;
    } catch (e) {
      return false;
    }
  }
}
