class FuelInventoryEntry {
  FuelInventoryEntry({
    required this.fuelType,
    required this.currentLevel,
    required this.capacity,
    this.lowLevelAlert,
    this.lastRefill,
  });

  final String fuelType;
  final double currentLevel;
  final double capacity;
  final double? lowLevelAlert;
  final String? lastRefill;

  factory FuelInventoryEntry.fromJson(Map<String, dynamic> json) {
    return FuelInventoryEntry(
      fuelType: json['fuel_type'] as String? ?? 'UNKNOWN',
      currentLevel: double.tryParse(json['quantity_liters'] as String? ?? '') ?? 0,
      capacity: double.tryParse(_nullableStr(json['capacity_liters']) ?? '') ?? 0,
      lowLevelAlert: double.tryParse(_nullableStr(json['low_level_alert_liters']) ?? ''),
      lastRefill: _nullableTime(json['last_refill_at']),
    );
  }

  // Backend sql.NullString marshals as {"String":"...","Valid":true}.
  static String? _nullableStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is! Map) return null;
    final m = v as Map<String, dynamic>;
    if (m['Valid'] != true) return null;
    return m['String'] is String ? m['String'] as String : null;
  }

  // Backend sql.NullTime marshals as {"Time":"...","Valid":true}.
  static String? _nullableTime(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is! Map) return null;
    final m = v as Map<String, dynamic>;
    if (m['Valid'] != true) return null;
    return m['Time'] is String ? m['Time'] as String : null;
  }

  double get percentFull {
    if (capacity <= 0) return 0;
    return (currentLevel / capacity) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'fuelType': fuelType,
      'currentLevel': currentLevel,
      'capacity': capacity,
      'lowLevelAlert': lowLevelAlert,
      'lastRefill': lastRefill,
    };
  }
}
