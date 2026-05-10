class Station {
  Station({
    required this.id,
    required this.name,
    this.district,
    this.region,
    this.status,
    this.address,
    this.country,
    this.contactNumber,
    this.operatingHours,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? district;
  final String? region;
  final String? status;
  final String? address;
  final String? country;
  final String? contactNumber;
  final String? operatingHours;
  final double? latitude;
  final double? longitude;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      district: json['district'] as String?,
      region: json['region'] as String?,
      status: json['status'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      contactNumber: json['contactNumber'] as String?,
      operatingHours: json['operatingHours'] as String?,
      latitude: (json['lat'] as num? ?? json['latitude'] as num?)?.toDouble(),
      longitude: (json['lng'] as num? ?? json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district': district,
      'region': region,
      'status': status,
      'address': address,
      'country': country,
      'contactNumber': contactNumber,
      'operatingHours': operatingHours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
