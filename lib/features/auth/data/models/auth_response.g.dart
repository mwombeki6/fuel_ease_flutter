// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map json) =>
    $checkedCreate(r'_$AuthResponseImpl', json, ($checkedConvert) {
      final val = _$AuthResponseImpl(
        user: $checkedConvert(
          'user',
          (v) => User.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
        token: $checkedConvert('token', (v) => v as String),
        expiresAt: $checkedConvert('expires_at', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'token': instance.token,
      'expires_at': instance.expiresAt,
    };
