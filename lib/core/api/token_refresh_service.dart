import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

/// Exchanges a persisted refresh token for a new access token.
///
/// Refreshes are single-flight so startup and concurrent failed requests never
/// rotate the same session more than once at a time.
class TokenRefreshService {
  TokenRefreshService(this._secureStorage, {Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.timeout,
              receiveTimeout: ApiConstants.timeout,
              sendTimeout: ApiConstants.timeout,
              headers: {
                ApiConstants.contentTypeKey: ApiConstants.jsonContentType,
                'Accept': ApiConstants.jsonContentType,
                ApiConstants.clientHeaderKey: ApiConstants.clientType,
              },
            ),
          );

  final SecureStorage _secureStorage;
  final Dio dio;
  Future<String?>? _refreshInFlight;
  int _generation = 0;
  bool _invalidated = false;

  bool get isInvalidated => _invalidated;

  static bool isSessionRejection(Object error) =>
      error is DioException &&
      (error.response?.statusCode == 401 || error.response?.statusCode == 403);

  Future<String?> refreshAccessToken() {
    if (_invalidated) return Future<String?>.value(null);
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    late final Future<String?> refresh;
    final generation = _generation;
    refresh = _performRefresh(generation).whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
    _refreshInFlight = refresh;
    return refresh;
  }

  /// Prevents this service from refreshing again until [beginSession].
  Future<void> invalidateSession() async {
    _invalidated = true;
    _generation++;
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }
  }

  /// Waits out stale refresh work, then starts a fresh auth generation.
  Future<void> beginSession() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }
    _generation++;
    _invalidated = false;
  }

  Future<String?> _performRefresh(int generation) async {
    if (_invalidated) return null;
    final refreshToken = await _secureStorage.getRefreshToken();
    final sessionId = await _secureStorage.read('session_id');
    if (generation != _generation) return null;
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return null;
    }

    final Response<Map<String, dynamic>> response;
    try {
      response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'session_id': sessionId, 'refresh_token': refreshToken},
      );
    } on DioException catch (error) {
      if (generation != _generation) return null;
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        try {
          await _secureStorage.clearAuth();
        } catch (_) {}
      }
      rethrow;
    }
    if (generation != _generation) return null;
    final responseData = response.data;
    final data = responseData?['data'];
    if (data is! Map) {
      await _clearInvalidSession();
      throw const FormatException('Invalid refresh response');
    }
    final values = Map<String, dynamic>.from(data);
    final tokensValue = values['tokens'];
    if (tokensValue is! Map) {
      await _clearInvalidSession();
      throw const FormatException('Invalid refresh token response');
    }
    final tokens = Map<String, dynamic>.from(tokensValue);
    final newAccessToken = tokens['access_token'] as String?;
    final newRefreshToken = tokens['refresh_token'] as String?;
    final newSessionId = values['session_id'] as String?;
    final effectiveRefreshToken = newRefreshToken ?? refreshToken;
    final effectiveSessionId = newSessionId ?? sessionId;
    if (newAccessToken == null ||
        newAccessToken.isEmpty ||
        effectiveRefreshToken.isEmpty ||
        effectiveSessionId.isEmpty) {
      await _clearInvalidSession();
      throw const FormatException('Incomplete refresh response');
    }

    final int expiresAt;
    try {
      expiresAt = _expiryMilliseconds(tokens['expires_at']);
    } on FormatException {
      await _clearInvalidSession();
      rethrow;
    }
    if (generation != _generation) return null;
    await _secureStorage.saveRefreshToken(effectiveRefreshToken);
    if (generation != _generation) return null;
    await _secureStorage.saveExpiresAt(expiresAt);
    if (generation != _generation) return null;
    await _secureStorage.save('session_id', effectiveSessionId);
    if (generation != _generation) return null;
    // Write access last so a partial refresh cannot look like a valid session.
    await _secureStorage.saveToken(newAccessToken);
    if (generation != _generation) return null;
    return newAccessToken;
  }

  Future<void> _clearInvalidSession() async {
    try {
      await _secureStorage.clearAuth();
    } catch (_) {}
  }
}

int _expiryMilliseconds(Object? value) {
  if (value is num) {
    final timestamp = value.toInt();
    return timestamp < 1000000000000 ? timestamp * 1000 : timestamp;
  }
  if (value is String) {
    final timestamp = int.tryParse(value);
    if (timestamp != null) {
      return timestamp < 1000000000000 ? timestamp * 1000 : timestamp;
    }
    final date = DateTime.tryParse(value);
    if (date != null) return date.millisecondsSinceEpoch;
  }
  throw const FormatException('Invalid token expiry');
}

final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  return TokenRefreshService(ref.watch(secureStorageProvider));
});
