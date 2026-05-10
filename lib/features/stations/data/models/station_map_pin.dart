class StationMapPin {
  StationMapPin({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.status,
    required this.region,
    required this.district,
    required this.activePumps,
    required this.hasSuspension,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final String status;
  final String region;
  final String district;
  final int activePumps;
  final bool hasSuspension;

  factory StationMapPin.fromJson(Map<String, dynamic> json) {
    return StationMapPin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      region: json['region'] as String? ?? '',
      district: json['district'] as String? ?? '',
      activePumps: json['active_pumps'] as int? ?? 0,
      hasSuspension: json['has_suspension'] as bool? ?? false,
    );
  }
}
