// Route data model

import 'student.dart';

class Route {
  final String id;
  final String name;
  final List<Student> students;

  Route({
    required this.id,
    required this.name,
    required this.students,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'students': students.map((s) => s.toJson()).toList(),
    };
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      name: json['name'] as String,
      students: (json['students'] as List<dynamic>)
          .map((s) => Student.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
