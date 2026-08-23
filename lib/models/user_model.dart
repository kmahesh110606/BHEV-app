/// User model representing authenticated EV Driver or Operator
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role; // 'customer', 'operator', 'admin'
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.role,
    this.emailVerified = false,
  });

  bool get isOperator => role == 'operator' || role == 'admin';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      emailVerified: json['emailVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'emailVerified': emailVerified,
    };
  }
}
