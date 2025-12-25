import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/fuel_session.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/recharge_payload.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';

/// Repository for wallet operations
class WalletRepository {
  WalletRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Get wallet summary for current customer
  Future<WalletSummary> getWalletSummary() async {
    try {
      final response = await _apiClient.get('/wallet/me');

      if (response.data['status'] == 'success') {
        // Extract wallet data
        final walletData = response.data['data']['wallet'];
        final wallet = Wallet.fromJson(walletData);

        return WalletSummary(
          wallet: wallet,
          totalTransactions: response.data['data']['totalTransactions'] as int?,
          totalSpent: (response.data['data']['totalSpent'] as num?)?.toDouble(),
          totalRecharged:
              (response.data['data']['totalRecharged'] as num?)?.toDouble(),
        );
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to get wallet',
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

  /// Get wallet transactions (ledger)
  Future<List<WalletTransaction>> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallet/me/transactions',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> transactionsData = response.data['data'];
        return transactionsData
            .map((json) => WalletTransaction.fromJson(json))
            .toList();
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to get transactions',
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

  /// Recharge wallet via M-Pesa or AzamPay
  Future<RechargeResponse> rechargeWallet(RechargePayload payload) async {
    try {
      final response = await _apiClient.post(
        '/wallet/me/recharge',
        data: payload.toJson(),
      );

      if (response.data['status'] == 'success') {
        return RechargeResponse.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Recharge failed',
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

  /// Get active fuel sessions
  Future<List<FuelSession>> getActiveSessions() async {
    try {
      final response = await _apiClient.get('/wallet/me/sessions');

      if (response.data['status'] == 'success') {
        final List<dynamic> sessionsData = response.data['data'];
        return sessionsData
            .map((json) => FuelSession.fromJson(json))
            .toList();
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to get sessions',
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

  /// Create a new fuel session
  Future<FuelSession> createSession({
    required String stationId,
    required double units,
  }) async {
    try {
      final response = await _apiClient.post(
        '/wallet/me/sessions',
        data: {
          'stationId': stationId,
          'units': units,
        },
      );

      if (response.data['status'] == 'success') {
        return FuelSession.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to create session',
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

  /// Get session by ID
  Future<FuelSession> getSessionById(String sessionId) async {
    try {
      final response = await _apiClient.get('/wallet/me/sessions/$sessionId');

      if (response.data['status'] == 'success') {
        return FuelSession.fromJson(response.data['data']);
      } else {
        throw ApiError(
          message: response.data['message'] ?? 'Failed to get session',
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
}

/// Provider for WalletRepository
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepository(apiClient);
});
