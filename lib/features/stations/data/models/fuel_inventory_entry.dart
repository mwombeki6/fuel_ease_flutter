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
      fuelType: json['fuelType'] as String? ?? 'UNKNOWN',
      currentLevel: (json['currentLevel'] as num?)?.toDouble() ?? 0,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0,
      lowLevelAlert: (json['lowLevelAlert'] as num?)?.toDouble(),
      lastRefill: json['lastRefill'] as String?,
    );
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
