import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fuel_ease_flutter/shared/models/user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

/// Authentication response from login/register endpoints
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required User user,
    required String token,
    required int expiresAt,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  const AuthResponse._();

  /// Check if token is expired
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > expiresAt;
  }

  /// Get remaining time until expiry
  Duration get timeUntilExpiry {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = expiresAt - now;
    return Duration(milliseconds: remaining > 0 ? remaining : 0);
  }
}
