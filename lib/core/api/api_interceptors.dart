import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';

/// Interceptor for adding authentication token to requests
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;
  final Logger _logger = Logger();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Check if token exists and is valid
      final hasValidToken = await _secureStorage.hasValidToken();

      if (hasValidToken) {
        final token = await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } else {
        // Token expired or doesn't exist
        final token = await _secureStorage.getToken();
        if (token != null) {
          _logger.w('Token expired or invalid');
          // Clear expired token
          await _secureStorage.clearAuth();
        }
      }

      handler.next(options);
    } catch (e, st) {
      _logger.e('Error in AuthInterceptor', error: e, stackTrace: st);
      handler.next(options);
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
