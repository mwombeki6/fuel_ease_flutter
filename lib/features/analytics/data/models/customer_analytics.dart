class CustomerAnalytics {
  CustomerAnalytics({
    required this.transactionCount,
    required this.totalLiters,
    required this.totalSpentTzs,
  });

  final int transactionCount;
  final double totalLiters;
  final double totalSpentTzs;

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      transactionCount: json['transactionCount'] as int? ?? 0,
      totalLiters: (json['totalLiters'] as num?)?.toDouble() ?? 0.0,
      totalSpentTzs: (json['totalSpentTzs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
