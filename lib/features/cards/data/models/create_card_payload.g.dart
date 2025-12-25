// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_card_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreateCardPayloadImpl _$$CreateCardPayloadImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CreateCardPayloadImpl',
      json,
      ($checkedConvert) {
        final val = _$CreateCardPayloadImpl(
          stationId: $checkedConvert('station_id', (v) => v as String),
          units: $checkedConvert('units', (v) => (v as num).toDouble()),
          pin: $checkedConvert('pin', (v) => v as String),
          recipientName: $checkedConvert('recipient_name', (v) => v as String?),
          recipientPhone: $checkedConvert(
            'recipient_phone',
            (v) => v as String?,
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'stationId': 'station_id',
        'recipientName': 'recipient_name',
        'recipientPhone': 'recipient_phone',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$$CreateCardPayloadImplToJson(
  _$CreateCardPayloadImpl instance,
) => <String, dynamic>{
  'station_id': instance.stationId,
  'units': instance.units,
  'pin': instance.pin,
  if (instance.recipientName case final value?) 'recipient_name': value,
  if (instance.recipientPhone case final value?) 'recipient_phone': value,
  if (instance.expiresAt?.toIso8601String() case final value?)
    'expires_at': value,
};

_$CreateCardResponseImpl _$$CreateCardResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CreateCardResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CreateCardResponseImpl(
          cardId: $checkedConvert('card_id', (v) => v as String),
          cardNumber: $checkedConvert('card_number', (v) => v as String),
          pin: $checkedConvert('pin', (v) => v as String),
          units: $checkedConvert('units', (v) => (v as num).toDouble()),
          qrCode: $checkedConvert('qr_code', (v) => v as String?),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'cardId': 'card_id',
        'cardNumber': 'card_number',
        'qrCode': 'qr_code',
      },
    );

Map<String, dynamic> _$$CreateCardResponseImplToJson(
  _$CreateCardResponseImpl instance,
) => <String, dynamic>{
  'card_id': instance.cardId,
  'card_number': instance.cardNumber,
  'pin': instance.pin,
  'units': instance.units,
  if (instance.qrCode case final value?) 'qr_code': value,
  if (instance.message case final value?) 'message': value,
};

_$UseCardPayloadImpl _$$UseCardPayloadImplFromJson(Map json) =>
    $checkedCreate(r'_$UseCardPayloadImpl', json, ($checkedConvert) {
      final val = _$UseCardPayloadImpl(
        cardNumber: $checkedConvert('card_number', (v) => v as String),
        pin: $checkedConvert('pin', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'cardNumber': 'card_number'});

Map<String, dynamic> _$$UseCardPayloadImplToJson(
  _$UseCardPayloadImpl instance,
) => <String, dynamic>{'card_number': instance.cardNumber, 'pin': instance.pin};
