import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';

/// Interceptor for adding authentication token and silently refreshing it on 401.
///
/// Concurrent 401 handling: a [Completer<String?>] acts as a queue lock.
/// The first 401 starts the refresh and stores the completer; subsequent 401s
/// await that same future. When the refresh completes, every waiter receives
/// the new token and independently retries its original request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;
  final Logger _logger = Logger();

  // Raw Dio used only for refresh and retry calls — bypasses this interceptor.
  final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.timeout,
    receiveTimeout: ApiConstants.timeout,
    headers: {'Content-Type': 'application/json'},
  ));

  // Non-null while a token refresh is in progress.
  // Completes with the new access token on success, or null on failure.
  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _secureStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (e, st) {
      _logger.e('Error in AuthInterceptor.onRequest', error: e, stackTrace: st);
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshPath = err.requestOptions.path.contains('/auth/refresh');

    if (!isUnauthorized || isRefreshPath) {
      handler.next(err);
      return;
    }

    // If the stored token is already newer than what this request used, a
    // concurrent request already completed a refresh. Retry immediately.
    final storedToken = await _secureStorage.getToken();
    final usedToken = err.requestOptions.headers['Authorization']
        ?.toString()
        .replaceFirst('Bearer ', '');
    if (storedToken != null && storedToken != usedToken) {
      await _retryWithToken(storedToken, err, handler);
      return;
    }

    // A refresh is already running — wait for its result, then retry or fail.
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        await _retryWithToken(newToken, err, handler);
      } else {
        handler.next(err);
      }
      return;
    }

    // This request is the first 401 — start the refresh.
    _refreshCompleter = Completer<String?>();
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      final sessionId = await _secureStorage.read('session_id');

      if (refreshToken == null || sessionId == null) {
        await _secureStorage.clearAuth();
        _refreshCompleter!.complete(null);
        handler.next(err);
        return;
      }

      final refreshResp = await _refreshDio.post('/auth/refresh', data: {
        'session_id': sessionId,
        'refresh_token': refreshToken,
      });

      final data = (refreshResp.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      final newAccess = tokens['access_token'] as String;
      final newRefresh = tokens['refresh_token'] as String;
      final expiresAt = (tokens['expires_at'] as num).toInt();
      final newSessionId = data['session_id'] as String;

      // Persist before completing — waiters might read storage on next request.
      await _secureStorage.saveToken(newAccess);
      await _secureStorage.saveRefreshToken(newRefresh);
      await _secureStorage.saveExpiresAt(expiresAt * 1000);
      await _secureStorage.save('session_id', newSessionId);

      // Unblock all waiters with the new token.
      _refreshCompleter!.complete(newAccess);
      await _retryWithToken(newAccess, err, handler);
    } catch (e) {
      _logger.w('Token refresh failed — logging out', error: e);
      await _secureStorage.clearAuth();
      _refreshCompleter!.complete(null);
      handler.next(err);
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _retryWithToken(
    String token,
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $token';
      final retryResp = await _refreshDio.fetch(retryOptions);
      handler.resolve(retryResp);
    } catch (_) {
      handler.next(err);
    }
  }
}

/// Interceptor for handling API errors
class ErrorInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = ApiError.fromDioException(err);

    _logger.e(
      'API Error: ${apiError.message}',
      error: err,
      stackTrace: err.stackTrace,
    );

    // Create new DioException with custom error
    final dioException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiError,
      stackTrace: err.stackTrace,
    );

    handler.next(dioException);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
}

/// Interceptor for logging requests and responses
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('''
📤 REQUEST
Method: ${options.method}
Path: ${options.path}
Headers: ${_sanitizeHeaders(options.headers)}
Query: ${options.queryParameters}
Data: ${options.data}
''');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('''
📥 RESPONSE
Status: ${response.statusCode}
Path: ${response.requestOptions.path}
Data: ${response.data}
''');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('''
❌ ERROR
Type: ${err.type}
Message: ${err.message}
Path: ${err.requestOptions.path}
Status: ${err.response?.statusCode}
Data: ${err.response?.data}
''');
    handler.next(err);
  }

  /// Sanitize headers to hide sensitive data
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = '***HIDDEN***';
    }

    return sanitized;
  }
}
