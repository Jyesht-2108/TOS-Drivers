// Student data model

class Student {
  final String id;
  final String name;
  final String? assignedRouteId;
  final String? parentName;
  final String? parentPhone;
  final String? grade;
  final String? section;
  final String? tenantId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Student({
    required this.id,
    required this.name,
    this.assignedRouteId,
    this.parentName,
    this.parentPhone,
    this.grade,
    this.section,
    this.tenantId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assignedRouteId': assignedRouteId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'grade': grade,
      'section': section,
      'tenant_id': tenantId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      assignedRouteId: json['assignedRouteId'] as String?,
      parentName: json['parentName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      grade: json['grade'] as String?,
      section: json['section'] as String?,
      tenantId: json['tenant_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
