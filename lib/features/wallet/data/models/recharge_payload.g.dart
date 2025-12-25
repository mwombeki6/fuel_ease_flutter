// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recharge_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RechargePayloadImpl _$$RechargePayloadImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RechargePayloadImpl',
      json,
      ($checkedConvert) {
        final val = _$RechargePayloadImpl(
          amountTzs: $checkedConvert('amount_tzs', (v) => (v as num).toInt()),
          msisdn: $checkedConvert('msisdn', (v) => v as String),
          stationId: $checkedConvert('station_id', (v) => v as String),
          provider: $checkedConvert('provider', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'amountTzs': 'amount_tzs', 'stationId': 'station_id'},
    );

Map<String, dynamic> _$$RechargePayloadImplToJson(
  _$RechargePayloadImpl instance,
) => <String, dynamic>{
  'amount_tzs': instance.amountTzs,
  'msisdn': instance.msisdn,
  'station_id': instance.stationId,
  if (instance.provider case final value?) 'provider': value,
};

_$RechargeResponseImpl _$$RechargeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RechargeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RechargeResponseImpl(
          transactionId: $checkedConvert('transaction_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          message: $checkedConvert('message', (v) => v as String?),
          reference: $checkedConvert('reference', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'transactionId': 'transaction_id'},
    );

Map<String, dynamic> _$$RechargeResponseImplToJson(
  _$RechargeResponseImpl instance,
) => <String, dynamic>{
  'transaction_id': instance.transactionId,
  'status': instance.status,
  if (instance.message case final value?) 'message': value,
  if (instance.reference case final value?) 'reference': value,
};
