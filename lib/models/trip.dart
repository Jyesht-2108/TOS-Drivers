// Trip data model

enum TripType {
  PICKUP,
  DROP;

  String toJson() => name;

  static TripType fromJson(String json) {
    return TripType.values.firstWhere((e) => e.name == json);
  }
}

enum TripStatus {
  ACTIVE,
  ENDED;

  String toJson() => name;

  static TripStatus fromJson(String json) {
    return TripStatus.values.firstWhere((e) => e.name == json);
  }
}

class Trip {
  final String id;
  final String routeId;
  final TripType tripType;
  final TripStatus status;
  final DateTime startTime;
  final DateTime? endTime;

  Trip({
    required this.id,
    required this.routeId,
    required this.tripType,
    required this.status,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'tripType': tripType.toJson(),
      'status': status.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      routeId: (json['routeId'] ?? json['route_id']) as String,
      tripType: TripType.fromJson((json['tripType'] ?? json['trip_type']) as String),
      status: TripStatus.fromJson(json['status'] as String),
      startTime: DateTime.parse((json['startTime'] ?? json['start_time']) as String),
      endTime: json['endTime'] != null || json['end_time'] != null
          ? DateTime.parse((json['endTime'] ?? json['end_time']) as String) 
          : null,
    );
  }
}
