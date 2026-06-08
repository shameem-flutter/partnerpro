class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phoneNumber,
  });

  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final int role;
  final String? phoneNumber;

  String get displayName {
    if (firstName.trim().isNotEmpty) {
      return firstName.trim();
    }
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    return email.trim();
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _parseInt(json['id']),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: _parseInt(json['role']),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone_number': phoneNumber,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
