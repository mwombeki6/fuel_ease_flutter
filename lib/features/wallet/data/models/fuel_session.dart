import 'package:freezed_annotation/freezed_annotation.dart';

part 'fuel_session.freezed.dart';
part 'fuel_session.g.dart';

/// Fuel session model for active dispensing sessions
@freezed
class FuelSession with _$FuelSession {
  const factory FuelSession({
    required String id,
    required String walletId,
    required String customerId,
    required String stationId,
    required double unitsHeld,
    required String status,
    String? pumpId,
    String? qrCode,
    String? numericToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _FuelSession;

  factory FuelSession.fromJson(Map<String, dynamic> json) =>
      _$FuelSessionFromJson(json);

  const FuelSession._();

  /// Check if session is active
  bool get isActive => status == 'active';

  /// Check if session is completed
  bool get isCompleted => status == 'completed';

  /// Check if session is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get remaining time until expiry
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }
}
