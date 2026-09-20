enum UserRole { patient, compounder }

class UserProfile {
  final String userId;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final UserRole role;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    this.role = UserRole.patient,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'age': age,
      'gender': gender,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      name: json['name'],
      phone: json['phone'],
      age: json['age'] ?? 25,
      gender: json['gender'] ?? 'Other',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
