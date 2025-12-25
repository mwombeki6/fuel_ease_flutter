// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginPayloadImpl _$$LoginPayloadImplFromJson(Map json) =>
    $checkedCreate(r'_$LoginPayloadImpl', json, ($checkedConvert) {
      final val = _$LoginPayloadImpl(
        email: $checkedConvert('email', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$$LoginPayloadImplToJson(_$LoginPayloadImpl instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};
