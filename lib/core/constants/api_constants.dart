import 'package:fuel_ease_flutter/core/constants/secrets.dart';

/// API configuration constants for FuelEase app
class ApiConstants {
  ApiConstants._();

  /// Base URL for the FuelEase API.
  /// Override at build time: flutter build apk --dart-define=API_BASE_URL=https://your.api.com/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.fdc.ink/api/v1',
  );

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

  /// Mapbox public access token — get yours at https://account.mapbox.com
  /// Set at build time: flutter build apk --dart-define=MAPBOX_TOKEN=pk.xxx
  /// Falls back to secrets.dart (gitignored) for local development.
  static const String mapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: kMapboxToken,
  );

  /// Mapbox dark map style tile URL
  static String mapboxDarkTileUrl(int z, int x, int y) =>
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/$z/$x/$y@2x?access_token=$mapboxToken';

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
