import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/analytics/data/models/customer_analytics.dart';
import 'package:fuel_ease_flutter/features/analytics/data/repositories/analytics_repository.dart';

final customerAnalyticsProvider =
    FutureProvider.autoDispose<CustomerAnalytics>((ref) async {
  return ref.watch(analyticsRepositoryProvider).getCustomerAnalytics();
});
