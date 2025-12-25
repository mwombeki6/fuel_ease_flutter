/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'FuelEase';

  /// App version
  static const String appVersion = '1.0.0';

  /// Minimum supported platform versions
  static const String minAndroidSdk = '21';
  static const String minIosVersion = '12.0';

  /// Shared preferences keys
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Cache durations
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 30);
  static const Duration longCacheDuration = Duration(hours: 24);

  /// Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  /// Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;

  /// QR Code
  static const Duration qrCodeRefreshInterval = Duration(seconds: 30);
  static const Duration dispensingTokenExpiry = Duration(minutes: 15);

  /// Map settings
  static const double defaultMapZoom = 13.0;
  static const double maxMapZoom = 18.0;
  static const double minMapZoom = 5.0;
  static const int defaultStationSearchRadius = 5000; // 5km in meters
}
