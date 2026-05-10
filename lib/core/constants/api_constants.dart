/// API configuration constants for FuelEase app
class ApiConstants {
  ApiConstants._();

  /// Base URL for the FuelEase API
  // Local network IP — works for both emulator and physical device on same Wi-Fi.
  // Change to production URL before release.
  static const String baseUrl = 'http://192.168.100.97:8080/api/v1';

  /// WebSocket base URL for real-time events
  static String get webSocketUrl {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return wsBase.endsWith('/api')
        ? wsBase.substring(0, wsBase.length - 4)
        : wsBase;
  }

  /// One-time ticket endpoint — POST with Bearer auth to receive a short-lived ticket.
  static const String wsTicketPath = '/ws/ticket';

  /// WebSocket event stream endpoint — connect with `?ticket=<uuid>`.
  static String get webSocketConnectPath => '/ws/events';

  /// Build realtime URL with a one-time ticket UUID (not a raw JWT).
  static String realtimeUrl(String ticket) =>
      '$webSocketUrl$webSocketConnectPath?ticket=$ticket';

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
