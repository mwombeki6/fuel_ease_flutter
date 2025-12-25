/// Route path constants for the app
class Routes {
  Routes._();

  // Auth routes
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main app routes (bottom navigation)
  static const String home = '/home';
  static const String fuel = '/fuel';
  static const String cards = '/cards';
  static const String analytics = '/analytics';
  static const String profile = '/profile';

  // Wallet routes
  static const String wallet = '/wallet';
  static const String walletRecharge = '/wallet/recharge';
  static const String walletTransactions = '/wallet/transactions';

  // Dispensing routes
  static const String createDispensingRequest = '/fuel/create-request';
  static const String dispensingRequests = '/fuel/requests';
  static String dispensingRequestDetails(String id) => '/fuel/requests/$id';
  static String dispensingToken(String token) => '/fuel/token/$token';
  static const String scanQR = '/fuel/scan';

  // Stations routes
  static const String stations = '/stations';
  static String stationDetails(String id) => '/stations/$id';

  // Cards routes
  static const String createCard = '/cards/create';
  static String cardDetails(String id) => '/cards/$id';

  // Settings routes
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
}
