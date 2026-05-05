import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/recharge_payload.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';

/// Repository for wallet operations against the Go backend.
class WalletRepository {
  WalletRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WalletSummary> getWalletSummary() async {
    try {
      final results = await Future.wait([
        _apiClient.get('/wallets/me'),
        _apiClient.get('/wallets/me/transactions',
            queryParameters: {'limit': 5, 'offset': 0}),
      ]);

      _assertSuccess(results[0]);
      final wallet =
          Wallet.fromJson(results[0].data['data'] as Map<String, dynamic>);

      List<WalletTransaction> recent = [];
      if (results[1].statusCode != null && results[1].statusCode! < 300) {
        final list = results[1].data['data'] as List? ?? [];
        recent = list
            .map((j) => WalletTransaction.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      return WalletSummary(wallet: wallet, recentTransactions: recent);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<List<WalletTransaction>> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallets/me/transactions',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      _assertSuccess(response);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((j) => WalletTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<TopUpResponse> topUpWallet(TopUpPayload payload) async {
    try {
      final response =
          await _apiClient.post('/wallets/me/topup', data: payload.toJson());
      _assertSuccess(response);
      return TopUpResponse.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  // Backward-compat alias used by existing screens
  Future<TopUpResponse> rechargeWallet(TopUpPayload payload) =>
      topUpWallet(payload);

  void _assertSuccess(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 300) {
      final data = response.data as Map<String, dynamic>?;
      final msg =
          (data?['error'] as Map?)?['message'] as String? ?? 'Request failed';
      throw ApiError(message: msg, statusCode: code);
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepository(apiClient);
});
