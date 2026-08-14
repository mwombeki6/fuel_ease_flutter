import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/core/api/api_interceptors.dart';

void main() {
  test('network log contains allowlisted metadata only', () {
    final log = formatNetworkLog(
      method: 'POST',
      path: '/auth/login',
      statusCode: 401,
      elapsedMilliseconds: 12,
      requestId: 'req-123',
    );

    expect(
      log,
      'HTTP method=POST path=/auth/login status=401 duration_ms=12 '
      'request_id=req-123',
    );
    expect(log, isNot(contains('password')));
    expect(log, isNot(contains('token')));
    expect(log, isNot(contains('Authorization')));
  });

  test('unsafe request IDs are omitted', () {
    final log = formatNetworkLog(
      method: 'GET',
      path: '/wallets/me',
      requestId: 'token=secret value',
    );

    expect(log, 'HTTP method=GET path=/wallets/me');
  });

  test('metadata formatter never includes supplied sensitive values', () {
    const sensitiveValues = [
      'secret-password',
      'bearer-token',
      'PIN-654321',
      '{"qr":"payload"}',
      'CVV-987',
      'PHONE-255700000000',
    ];
    final log = formatNetworkLog(method: 'POST', path: '/cards');

    for (final value in sensitiveValues) {
      expect(log, isNot(contains(value)));
    }
  });
}
