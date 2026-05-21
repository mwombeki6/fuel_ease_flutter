import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:fuel_ease_flutter/core/constants/api_constants.dart';

typedef RouteResult = ({
  List<LatLng> points,
  double distanceKm,
  int durationMin,
});

class MapboxDirectionsService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetches a driving route between [from] and [to] using the Mapbox Directions API.
  /// Returns null if routing fails (no route, offline, API error).
  static Future<RouteResult?> fetchRoute(LatLng from, LatLng to) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/directions/v5/mapbox/driving'
        '/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        queryParameters: {
          'geometries': 'geojson',
          'overview': 'full',
          'access_token': ApiConstants.mapboxToken,
        },
      );

      final routes = response.data?['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final coords =
          (route['geometry'] as Map<String, dynamic>)['coordinates'] as List;

      return (
        points: coords
            .map((c) => LatLng(
                  (c[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                ))
            .toList(),
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationMin: ((route['duration'] as num).toDouble() / 60).round(),
      );
    } catch (_) {
      return null;
    }
  }
}
