class Pump {
  Pump({
    required this.id,
    required this.stationId,
    required this.pumpNumber,
    required this.fuelType,
    required this.status,
    this.deviceId,
  });

  final String id;
  final String stationId;
  final int pumpNumber;
  final String fuelType;
  final String status;
  final String? deviceId;

  factory Pump.fromJson(Map<String, dynamic> json) {
    return Pump(
      id: json['id'] as String? ?? '',
      stationId: json['stationId'] as String? ?? '',
      pumpNumber: (json['pumpNumber'] as num?)?.toInt() ?? 0,
      fuelType: json['fuelType'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'UNKNOWN',
      deviceId: json['deviceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      'pumpNumber': pumpNumber,
      'fuelType': fuelType,
      'status': status,
      'deviceId': deviceId,
    };
  }
}
