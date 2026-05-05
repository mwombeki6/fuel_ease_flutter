import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Custom API error class for handling HTTP errors
class ApiError extends Equatable implements Exception {
  const ApiError({
    required this.message,
    this.statusCode,
    this.errors,
    this.stackTrace,
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;
  final StackTrace? stackTrace;

  /// Create ApiError from DioException
  factory ApiError.fromDioException(DioException exception) {
    String message;
    int? statusCode;
    Map<String, List<String>>? errors;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;

      case DioExceptionType.badResponse:
        statusCode = exception.response?.statusCode;
        final data = exception.response?.data;

        if (data is Map<String, dynamic>) {
          // Go backend: {"error": {"code": N, "message": "..."}}
          final errObj = data['error'];
          if (errObj is Map<String, dynamic>) {
            message = errObj['message'] as String? ?? 'An error occurred';
          } else {
            message = data['message'] as String? ?? 'An error occurred';
          }
        } else {
          message = 'An error occurred';
        }
        break;

      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;

      case DioExceptionType.connectionError:
        message = 'No internet connection';
        break;

      case DioExceptionType.badCertificate:
        message = 'Security error. Please check your connection.';
        break;

      case DioExceptionType.unknown:
        message = exception.message ?? 'An unexpected error occurred';
        break;
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      errors: errors,
      stackTrace: exception.stackTrace,
    );
  }

  /// Check if error is authentication related
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Check if error is server error
  bool get isServerError =>
      statusCode != null && statusCode! >= 500 && statusCode! < 600;

  /// Check if error is client error
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Check if error is network related
  bool get isNetworkError => statusCode == null;

  @override
  List<Object?> get props => [message, statusCode, errors];

  @override
  String toString() {
    final buffer = StringBuffer('ApiError: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (errors != null && errors!.isNotEmpty) {
      buffer.write('\nValidation Errors: $errors');
    }
    return buffer.toString();
  }
}
