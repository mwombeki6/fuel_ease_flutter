import 'package:freezed_annotation/freezed_annotation.dart';

part 'fuel_card.freezed.dart';
part 'fuel_card.g.dart';

/// Fuel card model for digital fuel vouchers
@freezed
class FuelCard with _$FuelCard {
  const factory FuelCard({
    required String id,
    required String customerId,
    required String stationId,
    required double units,
    required String status,
    required String cardNumber,
    String? pin,
    String? stationName,
    String? recipientName,
    String? recipientPhone,
    String? usedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    Map<String, dynamic>? metadata,
  }) = _FuelCard;

  factory FuelCard.fromJson(Map<String, dynamic> json) =>
      _$FuelCardFromJson(json);

  const FuelCard._();

  /// Check if card is active and usable
  bool get isActive => status == 'active';

  /// Check if card has been used
  bool get isUsed => status == 'used';

  /// Check if card is expired
  bool get isExpired {
    if (status == 'expired') return true;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if card is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Get card status color
  String get statusColor {
    switch (status) {
      case 'active':
        return 'success';
      case 'used':
        return 'info';
      case 'expired':
        return 'error';
      case 'cancelled':
        return 'error';
      default:
        return 'secondary';
    }
  }

  /// Get formatted status text
  String get formattedStatus {
    switch (status) {
      case 'active':
        return 'Active';
      case 'used':
        return 'Used';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  /// Get remaining days until expiry
  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inDays;
  }

  /// Check if card is about to expire (within 7 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days > 0 && days <= 7;
  }

  /// Get masked card number for display (e.g., "****1234")
  String get maskedCardNumber {
    if (cardNumber.length <= 4) return cardNumber;
    return '****${cardNumber.substring(cardNumber.length - 4)}';
  }

  /// Get masked PIN for display (e.g., "****")
  String get maskedPin {
    return '****';
  }
}
