import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/core/constants/api_constants.dart';

void main() {
  test('Mapbox token defaults to empty without a dart define', () {
    expect(ApiConstants.mapboxToken, isEmpty);
  });
}
