import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry<T> {
  CacheEntry({
    required this.data,
    required this.updatedAt,
  });

  final T data;
  final DateTime updatedAt;

  bool isStale(Duration maxAge) {
    return DateTime.now().difference(updatedAt) > maxAge;
  }
}

class AppCache {
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  Future<CacheEntry<T>?> get<T>(
    String key,
    T Function(Object? json) parser,
  ) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final updatedAtMs = decoded['updatedAt'] as int?;
      if (updatedAtMs == null) return null;
      final data = parser(decoded['data']);
      return CacheEntry(
        data: data,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String key, Object? data) async {
    final prefs = await _prefs;
    final payload = jsonEncode({
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    });
    await prefs.setString(key, payload);
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}
