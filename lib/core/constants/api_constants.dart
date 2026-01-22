/// API configuration constants for FuelEase app
class ApiConstants {
  ApiConstants._();

  /// Base URL for the FuelEase API
  static const String baseUrl =
      'https://fuel-ease-api.mwombekilubere.workers.dev/api';

  /// WebSocket base URL for real-time events
  static String get webSocketUrl {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return wsBase.endsWith('/api')
        ? wsBase.substring(0, wsBase.length - 4)
        : wsBase;
  }

  /// WebSocket event stream endpoint (token required)
  static String get webSocketConnectPath => '/ws/events';

  /// Build realtime URL with auth token
  static String realtimeUrl(String token) =>
      '$webSocketUrl$webSocketConnectPath?token=$token';

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
