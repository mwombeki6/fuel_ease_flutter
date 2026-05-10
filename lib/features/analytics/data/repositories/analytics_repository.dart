import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/analytics/data/models/customer_analytics.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CustomerAnalytics> getCustomerAnalytics() async {
    try {
      final response = await _apiClient.get('/analytics/customer/me');
      final code = response.statusCode ?? 0;
      if (code >= 300) {
        final data = response.data as Map<String, dynamic>?;
        final msg =
            (data?['error'] as Map?)?['message'] as String? ?? 'Request failed';
        throw ApiError(message: msg, statusCode: code);
      }
      return CustomerAnalytics.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(apiClientProvider));
});
