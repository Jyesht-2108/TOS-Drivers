// Attendance record data model

enum AttendanceStatus {
  PRESENT,
  ABSENT,
  UNMARKED;

  String toJson() => name;

  static AttendanceStatus fromJson(String? json) {
    if (json == null) return AttendanceStatus.UNMARKED;
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => AttendanceStatus.UNMARKED,
    );
  }
}

class AttendanceRecord {
  final String id; // Attendance record ID from backend
  final String studentId;
  final String studentName; // Student name from backend
  final String tripId;
  final AttendanceStatus status;
  final bool locked; // Backend uses 'locked' not 'isLocked'
  final String? markedBy;
  final DateTime? markedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.tripId,
    required this.status,
    required this.locked,
    this.markedBy,
    this.markedAt,
  });

  // Convenience getter for UI
  bool get isLocked => locked;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'trip_id': tripId,
      'status': status == AttendanceStatus.UNMARKED ? null : status.toJson(),
      'locked': locked,
      'marked_by': markedBy,
      'marked_at': markedAt?.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      tripId: json['trip_id'] as String,
      status: AttendanceStatus.fromJson(json['status'] as String?),
      locked: json['locked'] as bool? ?? false,
      markedBy: json['marked_by'] as String?,
      markedAt: json['marked_at'] != null 
          ? DateTime.parse(json['marked_at'] as String) 
          : null,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? tripId,
    AttendanceStatus? status,
    bool? locked,
    String? markedBy,
    DateTime? markedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      locked: locked ?? this.locked,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
    );
  }
}
