/// API configuration constants for FuelEase app
class ApiConstants {
  ApiConstants._();

  /// Base URL for the FuelEase API
  static const String baseUrl =
      'https://fuel-ease-api.mwombekilubere.workers.dev/api';

  /// WebSocket URL for real-time events
  static String get webSocketUrl {
    return baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  /// WebSocket events endpoint
  static String get webSocketEventsPath => '/ws/events';

  /// API request timeout duration
  static const Duration timeout = Duration(seconds: 15);

  /// API retry attempts
  static const int maxRetries = 3;

  /// Client identifier header value
  static const String clientType = 'mobile';

  /// Auth header key
  static const String authHeaderKey = 'Authorization';

  /// Client header key
  static const String clientHeaderKey = 'X-Client';

  /// Content type header key
  static const String contentTypeKey = 'Content-Type';

  /// JSON content type
  static const String jsonContentType = 'application/json';
}
