// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map json) => $checkedCreate(
  r'_$UserImpl',
  json,
  ($checkedConvert) {
    final val = _$UserImpl(
      id: $checkedConvert('id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      role: $checkedConvert('role', (v) => v as String),
      firstName: $checkedConvert('first_name', (v) => v as String),
      lastName: $checkedConvert('last_name', (v) => v as String),
      phoneNumber: $checkedConvert('phone_number', (v) => v as String?),
      profileImageUrl: $checkedConvert(
        'profile_image_url',
        (v) => v as String?,
      ),
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
    'firstName': 'first_name',
    'lastName': 'last_name',
    'phoneNumber': 'phone_number',
    'profileImageUrl': 'profile_image_url',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$$UserImplToJson(
  _$UserImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'role': instance.role,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  if (instance.phoneNumber case final value?) 'phone_number': value,
  if (instance.profileImageUrl case final value?) 'profile_image_url': value,
  if (instance.createdAt?.toIso8601String() case final value?)
    'created_at': value,
  if (instance.updatedAt?.toIso8601String() case final value?)
    'updated_at': value,
};
