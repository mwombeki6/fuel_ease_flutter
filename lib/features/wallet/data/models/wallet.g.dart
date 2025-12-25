// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletImpl _$$WalletImplFromJson(Map json) => $checkedCreate(
  r'_$WalletImpl',
  json,
  ($checkedConvert) {
    final val = _$WalletImpl(
      id: $checkedConvert('id', (v) => v as String),
      customerId: $checkedConvert('customer_id', (v) => v as String),
      balanceUnits: $checkedConvert(
        'balance_units',
        (v) => (v as num).toDouble(),
      ),
      reservedUnits: $checkedConvert(
        'reserved_units',
        (v) => (v as num).toDouble(),
      ),
      status: $checkedConvert('status', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'customerId': 'customer_id',
    'balanceUnits': 'balance_units',
    'reservedUnits': 'reserved_units',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$$WalletImplToJson(_$WalletImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'balance_units': instance.balanceUnits,
      'reserved_units': instance.reservedUnits,
      'status': instance.status,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };
