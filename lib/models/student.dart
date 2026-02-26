// Student data model

class Student {
  final String id;
  final String name;
  final String assignedRouteId;
  final String? parentName;
  final String? parentPhone;
  final String? grade;

  Student({
    required this.id,
    required this.name,
    required this.assignedRouteId,
    this.parentName,
    this.parentPhone,
    this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assignedRouteId': assignedRouteId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'grade': grade,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      assignedRouteId: json['assignedRouteId'] as String,
      parentName: json['parentName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      grade: json['grade'] as String?,
    );
  }
}
