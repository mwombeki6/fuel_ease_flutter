// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegisterPayloadImpl _$$RegisterPayloadImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RegisterPayloadImpl',
      json,
      ($checkedConvert) {
        final val = _$RegisterPayloadImpl(
          email: $checkedConvert('email', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
          firstName: $checkedConvert('first_name', (v) => v as String),
          lastName: $checkedConvert('last_name', (v) => v as String),
          phoneNumber: $checkedConvert('phone_number', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'first_name',
        'lastName': 'last_name',
        'phoneNumber': 'phone_number',
      },
    );

Map<String, dynamic> _$$RegisterPayloadImplToJson(
  _$RegisterPayloadImpl instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'phone_number': instance.phoneNumber,
};
