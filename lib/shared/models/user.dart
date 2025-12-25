import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User model representing authenticated user
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String role,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  const User._();

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Check if user is customer
  bool get isCustomer => role == 'customer';

  /// Check if user is admin
  bool get isAdmin => role == 'system_admin';

  /// Check if user is station manager
  bool get isStationManager =>
      role == 'station_manager' || role == 'station_admin';

  /// Check if user is regulator
  bool get isRegulator => role == 'regulator';
}
