import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AccountStateReset = Future<void> Function();

/// Overridden by the app root with invalidation for account-scoped providers.
final accountStateResetProvider = Provider<AccountStateReset>((ref) {
  return () async {
    throw StateError('Account state reset is not configured');
  };
});
