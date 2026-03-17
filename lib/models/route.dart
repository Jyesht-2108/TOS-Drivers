// Route data model

import 'student.dart';

class Route {
  final String id;
  final String name;
  final List<Student> students;
  final String? tenantId;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Route({
    required this.id,
    required this.name,
    this.students = const [],  // Default to empty list
    this.tenantId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'students': students.map((s) => s.toJson()).toList(),
      'tenant_id': tenantId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      name: json['name'] as String,
      students: json['students'] != null
          ? (json['students'] as List<dynamic>)
              .map((s) => Student.fromJson(s as Map<String, dynamic>))
              .toList()
          : [],  // Default to empty list if students not provided
      tenantId: json['tenant_id'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  
  // Helper method to create a copy with students
  Route copyWith({
    String? id,
    String? name,
    List<Student>? students,
    String? tenantId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      students: students ?? this.students,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
