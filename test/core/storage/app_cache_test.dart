import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_ease_flutter/core/storage/app_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removeByPrefix removes only matching cached data', () async {
    SharedPreferences.setMockInitialValues({
      'stations.list.v1': 'stations',
      'stations.one.detail.v1': 'detail',
      'fe_theme': 'dark',
    });

    await AppCache().removeByPrefix('stations.');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('stations.list.v1'), isFalse);
    expect(preferences.containsKey('stations.one.detail.v1'), isFalse);
    expect(preferences.getString('fe_theme'), 'dark');
  });
}
