// Attendance record data model

enum AttendanceStatus {
  PRESENT,
  ABSENT,
  UNMARKED;

  String toJson() => name;

  static AttendanceStatus fromJson(String json) {
    return AttendanceStatus.values.firstWhere((e) => e.name == json);
  }
}

class AttendanceRecord {
  final String studentId;
  final String tripId;
  final AttendanceStatus status;
  final bool isLocked;
  final DateTime? markedAt;

  AttendanceRecord({
    required this.studentId,
    required this.tripId,
    required this.status,
    required this.isLocked,
    this.markedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'tripId': tripId,
      'status': status.toJson(),
      'isLocked': isLocked,
      'markedAt': markedAt?.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'] as String,
      tripId: json['tripId'] as String,
      status: AttendanceStatus.fromJson(json['status'] as String),
      isLocked: json['isLocked'] as bool,
      markedAt: json['markedAt'] != null 
          ? DateTime.parse(json['markedAt'] as String) 
          : null,
    );
  }
}
