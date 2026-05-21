import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:fuel_ease_flutter/core/constants/api_constants.dart';

class GeocodingResult {
  const GeocodingResult({
    required this.name,
    required this.fullName,
    required this.center,
    required this.type,
  });

  final String name;
  final String fullName;
  final LatLng center;
  final String type;

  IconType get iconType {
    if (type == 'poi') return IconType.poi;
    if (type == 'address') return IconType.address;
    return IconType.place;
  }
}

enum IconType { poi, address, place }

class MapboxGeocodingService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Geocode [query] against Tanzania, optionally biasing results toward [proximity].
  /// Returns up to 5 suggestions. Returns empty list on any error.
  static Future<List<GeocodingResult>> suggest(
    String query, {
    LatLng? proximity,
  }) async {
    if (query.trim().length < 2) return [];
    try {
      final params = <String, dynamic>{
        'country': 'TZ',
        'limit': 5,
        'types': 'poi,place,locality,neighborhood,address',
        'language': 'en',
        'access_token': ApiConstants.mapboxToken,
      };
      if (proximity != null) {
        params['proximity'] = '${proximity.longitude},${proximity.latitude}';
      }

      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json',
        queryParameters: params,
      );

      final features = response.data?['features'] as List?;
      if (features == null) return [];

      return features.map((f) {
        final props = f as Map<String, dynamic>;
        final coords = (props['center'] as List).cast<num>();
        final placeType =
            ((props['place_type'] as List?)?.firstOrNull as String?) ?? 'place';
        final text = props['text'] as String? ?? '';
        final placeName = props['place_name'] as String? ?? text;
        final shortName = text.isNotEmpty ? text : placeName;
        // Strip leading component from place_name to get a shorter subtitle
        final subtitle = placeName.contains(', ')
            ? placeName.substring(placeName.indexOf(', ') + 2)
            : placeName;

        return GeocodingResult(
          name: shortName,
          fullName: subtitle,
          center: LatLng(coords[1].toDouble(), coords[0].toDouble()),
          type: placeType,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
