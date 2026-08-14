import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/core/api/api_interceptors.dart';
import 'package:fuel_ease_flutter/core/api/token_refresh_service.dart';

bool apiValidateStatus(int? status) =>
    status != null && status >= 200 && status < 400;

/// Main API client for making HTTP requests
class ApiClient {
  ApiClient(
    this._secureStorage, {
    TokenRefreshService? tokenRefreshService,
    Dio? dio,
    bool enableLogging = kDebugMode,
  }) {
    _dio =
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
            validateStatus: apiValidateStatus,
          ),
        );

    final refreshService =
        tokenRefreshService ?? TokenRefreshService(_secureStorage);
    _dio.interceptors.addAll([
      AuthInterceptor(_secureStorage, refreshService),
      ErrorInterceptor(),
      if (enableLogging) LoggingInterceptor(),
    ]);
  }

  final SecureStorage _secureStorage;
  late final Dio _dio;

  /// Get the configured Dio instance
  Dio get dio => _dio;

  /// Make GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Download file
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    void Function(int, int)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) async {
    return await _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      options: options,
    );
  }
}

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final tokenRefreshService = ref.watch(tokenRefreshServiceProvider);
  return ApiClient(secureStorage, tokenRefreshService: tokenRefreshService);
});

/// Provider for Dio instance
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});
