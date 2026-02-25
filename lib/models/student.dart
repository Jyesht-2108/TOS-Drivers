// Student data model

class Student {
  final String id;
  final String name;
  final String assignedRouteId;

  Student({
    required this.id,
    required this.name,
    required this.assignedRouteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assignedRouteId': assignedRouteId,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      assignedRouteId: json['assignedRouteId'] as String,
    );
  }
}
