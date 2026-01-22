class Station {
  Station({
    required this.id,
    required this.name,
    this.city,
    this.state,
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
  final String? city;
  final String? state;
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
      city: json['city'] as String?,
      state: json['state'] as String?,
      status: json['status'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      contactNumber: json['contactNumber'] as String?,
      operatingHours: json['operatingHours'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
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
