// User data model

enum UserRole {
  DRIVER;

  String toJson() => name;

  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere((e) => e.name == json);
  }
}

class User {
  final String id;
  final String phone;
  final UserRole role;
  final String token;
  final String? name;
  final String? email;

  User({
    required this.id,
    required this.phone,
    required this.role,
    required this.token,
    this.name,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'role': role.toJson(),
      'token': token,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      role: UserRole.fromJson(json['role'] as String),
      token: json['token'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}
