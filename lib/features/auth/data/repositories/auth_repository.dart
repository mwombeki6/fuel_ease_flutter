import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/auth_response.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/login_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/register_payload.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

/// Repository for authentication operations against the Go backend.
class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponse> login(LoginPayload payload) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: payload.toJson(),
      );
      _assertSuccess(response);
      return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<AuthResponse> register(RegisterPayload payload) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        // Manually build JSON: freezed generates camelCase, Go expects snake_case
        data: {
          'email': payload.email,
          'password': payload.password,
          'first_name': payload.firstName,
          'last_name': payload.lastName,
          if (payload.phoneNumber.isNotEmpty) 'phone': payload.phoneNumber,
        },
      );
      _assertSuccess(response);
      return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/users/me');
      _assertSuccess(response);
      return User.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<User> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.put('/users/me', data: updates);
      _assertSuccess(response);
      return User.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<void> logout(String sessionId) async {
    try {
      await _apiClient.post('/auth/logout', data: {'session_id': sessionId});
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<void> registerPushToken(String token, String platform) async {
    try {
      await _apiClient.post(
        '/users/me/push-token',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (_) {
      // Non-critical — push token failure must not block the user
    }
  }

  void _assertSuccess(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 300) {
      final data = response.data as Map<String, dynamic>?;
      final msg = (data?['error'] as Map?)?['message'] as String? ?? 'Request failed';
      throw ApiError(message: msg, statusCode: code);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
