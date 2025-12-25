import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/auth_response.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/login_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/register_payload.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

/// Repository for authentication operations
class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Login with email and password
  Future<AuthResponse> login(LoginPayload payload) async {
    try {
      final response = await _apiClient.post(
        '/users/login',
        data: payload.toJson(),
      );

      if (response.data['status'] == 'success') {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  /// Register new customer account
  Future<AuthResponse> register(RegisterPayload payload) async {
    try {
      final response = await _apiClient.post(
        '/users/register',
        data: payload.toJson(),
      );

      if (response.data['status'] == 'success') {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  /// Get current authenticated user
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/users/me');

      if (response.data['status'] == 'success') {
        return User.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to get user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch(
        '/users/me',
        data: updates,
      );

      if (response.data['status'] == 'success') {
        return User.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  /// Update push notification token
  Future<void> updatePushToken(String token, String platform) async {
    try {
      await _apiClient.post(
        '/users/me/push-token',
        data: {
          'token': token,
          'platform': platform,
        },
      );
    } on DioException catch (e) {
      // Don't throw - push token update failure shouldn't block login
      if (e.error is ApiError) {
        return;
      }
    }
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
