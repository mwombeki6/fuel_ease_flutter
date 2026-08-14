import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/core/api/token_refresh_service.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

/// Interceptor for adding authentication token and silently refreshing it on 401.
///
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._secureStorage,
    this._tokenRefreshService, {
    Dio? retryDio,
  }) : _retryDio = retryDio ?? _tokenRefreshService.dio;

  final SecureStorage _secureStorage;
  final TokenRefreshService _tokenRefreshService;
  final Dio _retryDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (!_isPublicAuthPath(options.path)) {
        final token = await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    } catch (_) {
      if (!handler.isCompleted) handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final isUnauthorized = err.response?.statusCode == 401;
      if (!isUnauthorized || _isPublicAuthPath(err.requestOptions.path)) {
        handler.next(err);
        return;
      }
      if (_tokenRefreshService.isInvalidated) {
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

      final newToken = await _tokenRefreshService.refreshAccessToken();
      if (newToken == null) {
        if (!handler.isCompleted) handler.next(err);
        return;
      }
      await _retryWithToken(newToken, err, handler);
    } catch (error) {
      try {
        if (TokenRefreshService.isSessionRejection(error)) {
          await _secureStorage.clearAuth();
        }
      } catch (_) {
        // Preserve the original 401 when secure storage cleanup also fails.
      } finally {
        if (!handler.isCompleted) handler.next(err);
      }
    }
  }

  Future<void> _retryWithToken(
    String token,
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $token',
        },
      );
      final retryResp = await _retryDio.fetch(retryOptions);
      handler.resolve(retryResp);
    } on DioException catch (retryError) {
      if (TokenRefreshService.isSessionRejection(retryError)) {
        try {
          await _secureStorage.clearAuth();
        } catch (_) {}
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isPublicAuthPath(String path) =>
      path == '/auth/login' ||
      path.endsWith('/api/v1/auth/login') ||
      path == '/auth/register' ||
      path.endsWith('/api/v1/auth/register') ||
      path == '/auth/refresh' ||
      path.endsWith('/api/v1/auth/refresh');
}

/// Interceptor for handling API errors
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = ApiError.fromDioException(err);

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
}

const _requestStartedAtKey = 'network_log_started_at';

String formatNetworkLog({
  required String method,
  required String path,
  int? statusCode,
  int? elapsedMilliseconds,
  String? requestId,
}) {
  final fields = <String>['method=$method', 'path=$path'];
  if (statusCode != null) fields.add('status=$statusCode');
  if (elapsedMilliseconds != null) {
    fields.add('duration_ms=$elapsedMilliseconds');
  }
  final safeRequestId = _safeRequestId(requestId);
  if (safeRequestId != null) fields.add('request_id=$safeRequestId');
  return 'HTTP ${fields.join(' ')}';
}

String? _safeRequestId(String? value) {
  if (value == null || value.isEmpty || value.length > 128) return null;
  return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value) ? value : null;
}

/// Metadata-only HTTP logging. Bodies, query values, and headers are omitted.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({void Function(String message)? log})
    : _log = log ?? _defaultLog;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 120,
      colors: true,
      printEmojis: false,
    ),
  );
  final void Function(String message) _log;

  static void _defaultLog(String message) => _logger.d(message);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_requestStartedAtKey] = Stopwatch()..start();
    _log(formatNetworkLog(method: options.method, path: options.uri.path));
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    _log(
      formatNetworkLog(
        method: options.method,
        path: options.uri.path,
        statusCode: response.statusCode,
        elapsedMilliseconds: _elapsedMilliseconds(options),
        requestId: _requestId(response.headers),
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    _log(
      formatNetworkLog(
        method: options.method,
        path: options.uri.path,
        statusCode: err.response?.statusCode,
        elapsedMilliseconds: _elapsedMilliseconds(options),
        requestId: _requestId(err.response?.headers),
      ),
    );
    handler.next(err);
  }

  int? _elapsedMilliseconds(RequestOptions options) {
    final stopwatch = options.extra.remove(_requestStartedAtKey);
    if (stopwatch is! Stopwatch) return null;
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  String? _requestId(Headers? headers) =>
      headers?['x-request-id']?.firstOrNull ??
      headers?['x-correlation-id']?.firstOrNull;
}
