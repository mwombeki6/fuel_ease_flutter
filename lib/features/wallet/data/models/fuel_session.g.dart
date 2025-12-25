// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FuelSessionImpl _$$FuelSessionImplFromJson(Map json) => $checkedCreate(
  r'_$FuelSessionImpl',
  json,
  ($checkedConvert) {
    final val = _$FuelSessionImpl(
      id: $checkedConvert('id', (v) => v as String),
      walletId: $checkedConvert('wallet_id', (v) => v as String),
      customerId: $checkedConvert('customer_id', (v) => v as String),
      stationId: $checkedConvert('station_id', (v) => v as String),
      unitsHeld: $checkedConvert('units_held', (v) => (v as num).toDouble()),
      status: $checkedConvert('status', (v) => v as String),
      pumpId: $checkedConvert('pump_id', (v) => v as String?),
      qrCode: $checkedConvert('qr_code', (v) => v as String?),
      numericToken: $checkedConvert('numeric_token', (v) => v as String?),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      completedAt: $checkedConvert(
        'completed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'walletId': 'wallet_id',
    'customerId': 'customer_id',
    'stationId': 'station_id',
    'unitsHeld': 'units_held',
    'pumpId': 'pump_id',
    'qrCode': 'qr_code',
    'numericToken': 'numeric_token',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
    'completedAt': 'completed_at',
  },
);

Map<String, dynamic> _$$FuelSessionImplToJson(_$FuelSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wallet_id': instance.walletId,
      'customer_id': instance.customerId,
      'station_id': instance.stationId,
      'units_held': instance.unitsHeld,
      'status': instance.status,
      if (instance.pumpId case final value?) 'pump_id': value,
      if (instance.qrCode case final value?) 'qr_code': value,
      if (instance.numericToken case final value?) 'numeric_token': value,
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expires_at': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.completedAt?.toIso8601String() case final value?)
        'completed_at': value,
    };
