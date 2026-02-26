// Attendance state management with Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../services/attendance_service.dart';

// Attendance state class
class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;

  const AttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Clear error
  AttendanceState clearError() {
    return AttendanceState(
      records: records,
      isLoading: isLoading,
      error: null,
    );
  }

  // Get attendance record for a specific student
  AttendanceRecord? getRecordForStudent(String studentId) {
    try {
      return records.firstWhere((record) => record.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  // Check if all students are marked
  bool get allMarked {
    return records.isNotEmpty &&
        records.every((record) => record.status != AttendanceStatus.UNMARKED);
  }

  // Count of marked students
  int get markedCount {
    return records.where((record) => record.status != AttendanceStatus.UNMARKED).length;
  }

  // Count of present students
  int get presentCount {
    return records.where((record) => record.status == AttendanceStatus.PRESENT).length;
  }

  // Count of absent students
  int get absentCount {
    return records.where((record) => record.status == AttendanceStatus.ABSENT).length;
  }
}

// Attendance notifier
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceService _attendanceService;

  AttendanceNotifier(this._attendanceService) : super(const AttendanceState());

  // Initialize attendance for a trip
  void initializeAttendance(String tripId, List<Student> students) {
    _attendanceService.initializeAttendanceForTrip(tripId, students);
    loadAttendanceForTrip(tripId);
  }

  // Load attendance records for a trip
  Future<void> loadAttendanceForTrip(String tripId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final records = await _attendanceService.getAttendanceForTrip(tripId);
      state = AttendanceState(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Mark attendance for a student
  Future<void> markAttendance(
    String studentId,
    String tripId,
    AttendanceStatus status,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedRecord = await _attendanceService.markAttendance(
        studentId,
        tripId,
        status,
      );

      // Update the record in the list
      final updatedRecords = state.records.map((record) {
        if (record.studentId == studentId) {
          return updatedRecord;
        }
        return record;
      }).toList();

      state = AttendanceState(records: updatedRecords, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Check if attendance is locked for a student
  bool isLocked(String studentId, String tripId) {
    return _attendanceService.isAttendanceLocked(studentId, tripId);
  }

  // Clear attendance records (e.g., when leaving attendance screen)
  void clearRecords() {
    state = const AttendanceState();
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// Provider for AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

// Provider for AttendanceNotifier
final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return AttendanceNotifier(attendanceService);
});
