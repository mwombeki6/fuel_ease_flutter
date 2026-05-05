import 'package:fuel_ease_flutter/shared/models/user.dart';

/// Token pair from Go backend auth response.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresAt; // Unix seconds

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresAt: (json['expires_at'] as num).toInt(),
      );
}

/// Authentication response from login/register endpoints.
class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.tokens,
    required this.sessionId,
  });

  final User user;
  final TokenPair tokens;
  final String sessionId;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        tokens: TokenPair.fromJson(json['tokens'] as Map<String, dynamic>),
        sessionId: json['session_id'] as String,
      );
}
