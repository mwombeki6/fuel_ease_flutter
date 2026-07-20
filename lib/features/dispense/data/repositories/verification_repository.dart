import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/session_verification.dart';

/// REST access for a single dispense request's fuel-session verification
/// state. Mirrors [DispenseRepository]'s error handling exactly — same
/// success-envelope assertion, same `ApiError.fromDioException` mapping —
/// so callers get consistent error shapes across the feature.
class VerificationRepository {
  VerificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<SessionVerification> fetch(String requestId) async {
    try {
      final response =
          await _apiClient.get('/dispense/$requestId/verification');
      _assertSuccess(response);
      return SessionVerification.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  void _assertSuccess(Response response) {
    if ((response.statusCode ?? 0) >= 300) {
      final data = response.data;
      final message = (data is Map)
          ? (data['error']?['message'] ?? data['message'] ?? 'Request failed')
          : 'Request failed';
      throw ApiError(message: message.toString());
    }
  }
}

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.read(apiClientProvider));
});
