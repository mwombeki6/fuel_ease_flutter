// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletTransactionImpl _$$WalletTransactionImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WalletTransactionImpl',
      json,
      ($checkedConvert) {
        final val = _$WalletTransactionImpl(
          id: $checkedConvert('id', (v) => v as String),
          walletId: $checkedConvert('wallet_id', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          units: $checkedConvert('units', (v) => (v as num).toDouble()),
          balanceAfter: $checkedConvert(
            'balance_after',
            (v) => (v as num).toDouble(),
          ),
          reference: $checkedConvert('reference', (v) => v as String?),
          description: $checkedConvert('description', (v) => v as String?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'walletId': 'wallet_id',
        'balanceAfter': 'balance_after',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$$WalletTransactionImplToJson(
  _$WalletTransactionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'wallet_id': instance.walletId,
  'type': instance.type,
  'units': instance.units,
  'balance_after': instance.balanceAfter,
  if (instance.reference case final value?) 'reference': value,
  if (instance.description case final value?) 'description': value,
  if (instance.createdAt?.toIso8601String() case final value?)
    'created_at': value,
};
