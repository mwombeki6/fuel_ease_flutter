// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FuelCardImpl _$$FuelCardImplFromJson(Map json) => $checkedCreate(
  r'_$FuelCardImpl',
  json,
  ($checkedConvert) {
    final val = _$FuelCardImpl(
      id: $checkedConvert('id', (v) => v as String),
      customerId: $checkedConvert('customer_id', (v) => v as String),
      stationId: $checkedConvert('station_id', (v) => v as String),
      units: $checkedConvert('units', (v) => (v as num).toDouble()),
      status: $checkedConvert('status', (v) => v as String),
      cardNumber: $checkedConvert('card_number', (v) => v as String),
      pin: $checkedConvert('pin', (v) => v as String?),
      stationName: $checkedConvert('station_name', (v) => v as String?),
      recipientName: $checkedConvert('recipient_name', (v) => v as String?),
      recipientPhone: $checkedConvert('recipient_phone', (v) => v as String?),
      usedBy: $checkedConvert('used_by', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      usedAt: $checkedConvert(
        'used_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      metadata: $checkedConvert(
        'metadata',
        (v) => (v as Map?)?.map((k, e) => MapEntry(k as String, e)),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'customerId': 'customer_id',
    'stationId': 'station_id',
    'cardNumber': 'card_number',
    'stationName': 'station_name',
    'recipientName': 'recipient_name',
    'recipientPhone': 'recipient_phone',
    'usedBy': 'used_by',
    'createdAt': 'created_at',
    'expiresAt': 'expires_at',
    'usedAt': 'used_at',
  },
);

Map<String, dynamic> _$$FuelCardImplToJson(
  _$FuelCardImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'customer_id': instance.customerId,
  'station_id': instance.stationId,
  'units': instance.units,
  'status': instance.status,
  'card_number': instance.cardNumber,
  if (instance.pin case final value?) 'pin': value,
  if (instance.stationName case final value?) 'station_name': value,
  if (instance.recipientName case final value?) 'recipient_name': value,
  if (instance.recipientPhone case final value?) 'recipient_phone': value,
  if (instance.usedBy case final value?) 'used_by': value,
  if (instance.createdAt?.toIso8601String() case final value?)
    'created_at': value,
  if (instance.expiresAt?.toIso8601String() case final value?)
    'expires_at': value,
  if (instance.usedAt?.toIso8601String() case final value?) 'used_at': value,
  if (instance.metadata case final value?) 'metadata': value,
};
