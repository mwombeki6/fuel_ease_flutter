/// User model matching Go backend response schema.
class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.status,
    this.companyName,
    this.createdAt,
  });

  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? status;
  final String? companyName;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        phone: json['phone'] as String?,
        status: json['status'] as String?,
        companyName: json['company_name'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (status != null) 'status': status,
        if (companyName != null) 'company_name': companyName,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    String? phone,
    String? status,
    String? companyName,
    DateTime? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        role: role ?? this.role,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        companyName: companyName ?? this.companyName,
        createdAt: createdAt ?? this.createdAt,
      );

  String get fullName => '$firstName $lastName';
  bool get isCustomer => role == 'customer';
  bool get isAdmin => role == 'system_admin';
  bool get isStationManager =>
      role == 'station_manager' || role == 'station_admin';
  bool get isRegulator => role == 'regulator';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
