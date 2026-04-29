enum UserRole { guard, student, sao, guidance }

class User {
  final String id;
  final String username;
  final String password;
  final String name;
  final UserRole role;
  final String? gradeSection;
  final String? contactNumber;
  final String? studentNo;
  final String? token;
  final String? status;
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.gradeSection,
    this.contactNumber,
    this.studentNo,
    this.token,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'role': role.name,
      'gradeSection': gradeSection,
      'contactNumber': contactNumber,
      'studentNo': studentNo,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      role: UserRole.values.firstWhere((r) => r.name == map['role']),
      gradeSection: map['gradeSection'],
      contactNumber: map['contactNumber'],
      studentNo: map['studentNo'],
      status: map['status'],
    );
  }
}
