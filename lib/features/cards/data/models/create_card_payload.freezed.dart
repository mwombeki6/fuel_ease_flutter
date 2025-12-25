// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_card_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreateCardPayload _$CreateCardPayloadFromJson(Map<String, dynamic> json) {
  return _CreateCardPayload.fromJson(json);
}

/// @nodoc
mixin _$CreateCardPayload {
  String get stationId => throw _privateConstructorUsedError;
  double get units => throw _privateConstructorUsedError;
  String get pin => throw _privateConstructorUsedError;
  String? get recipientName => throw _privateConstructorUsedError;
  String? get recipientPhone => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this CreateCardPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateCardPayloadCopyWith<CreateCardPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateCardPayloadCopyWith<$Res> {
  factory $CreateCardPayloadCopyWith(
    CreateCardPayload value,
    $Res Function(CreateCardPayload) then,
  ) = _$CreateCardPayloadCopyWithImpl<$Res, CreateCardPayload>;
  @useResult
  $Res call({
    String stationId,
    double units,
    String pin,
    String? recipientName,
    String? recipientPhone,
    DateTime? expiresAt,
  });
}

/// @nodoc
class _$CreateCardPayloadCopyWithImpl<$Res, $Val extends CreateCardPayload>
    implements $CreateCardPayloadCopyWith<$Res> {
  _$CreateCardPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stationId = null,
    Object? units = null,
    Object? pin = null,
    Object? recipientName = freezed,
    Object? recipientPhone = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            stationId: null == stationId
                ? _value.stationId
                : stationId // ignore: cast_nullable_to_non_nullable
                      as String,
            units: null == units
                ? _value.units
                : units // ignore: cast_nullable_to_non_nullable
                      as double,
            pin: null == pin
                ? _value.pin
                : pin // ignore: cast_nullable_to_non_nullable
                      as String,
            recipientName: freezed == recipientName
                ? _value.recipientName
                : recipientName // ignore: cast_nullable_to_non_nullable
                      as String?,
            recipientPhone: freezed == recipientPhone
                ? _value.recipientPhone
                : recipientPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateCardPayloadImplCopyWith<$Res>
    implements $CreateCardPayloadCopyWith<$Res> {
  factory _$$CreateCardPayloadImplCopyWith(
    _$CreateCardPayloadImpl value,
    $Res Function(_$CreateCardPayloadImpl) then,
  ) = __$$CreateCardPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String stationId,
    double units,
    String pin,
    String? recipientName,
    String? recipientPhone,
    DateTime? expiresAt,
  });
}

/// @nodoc
class __$$CreateCardPayloadImplCopyWithImpl<$Res>
    extends _$CreateCardPayloadCopyWithImpl<$Res, _$CreateCardPayloadImpl>
    implements _$$CreateCardPayloadImplCopyWith<$Res> {
  __$$CreateCardPayloadImplCopyWithImpl(
    _$CreateCardPayloadImpl _value,
    $Res Function(_$CreateCardPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stationId = null,
    Object? units = null,
    Object? pin = null,
    Object? recipientName = freezed,
    Object? recipientPhone = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _$CreateCardPayloadImpl(
        stationId: null == stationId
            ? _value.stationId
            : stationId // ignore: cast_nullable_to_non_nullable
                  as String,
        units: null == units
            ? _value.units
            : units // ignore: cast_nullable_to_non_nullable
                  as double,
        pin: null == pin
            ? _value.pin
            : pin // ignore: cast_nullable_to_non_nullable
                  as String,
        recipientName: freezed == recipientName
            ? _value.recipientName
            : recipientName // ignore: cast_nullable_to_non_nullable
                  as String?,
        recipientPhone: freezed == recipientPhone
            ? _value.recipientPhone
            : recipientPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateCardPayloadImpl implements _CreateCardPayload {
  const _$CreateCardPayloadImpl({
    required this.stationId,
    required this.units,
    required this.pin,
    this.recipientName,
    this.recipientPhone,
    this.expiresAt,
  });

  factory _$CreateCardPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateCardPayloadImplFromJson(json);

  @override
  final String stationId;
  @override
  final double units;
  @override
  final String pin;
  @override
  final String? recipientName;
  @override
  final String? recipientPhone;
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'CreateCardPayload(stationId: $stationId, units: $units, pin: $pin, recipientName: $recipientName, recipientPhone: $recipientPhone, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateCardPayloadImpl &&
            (identical(other.stationId, stationId) ||
                other.stationId == stationId) &&
            (identical(other.units, units) || other.units == units) &&
            (identical(other.pin, pin) || other.pin == pin) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.recipientPhone, recipientPhone) ||
                other.recipientPhone == recipientPhone) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    stationId,
    units,
    pin,
    recipientName,
    recipientPhone,
    expiresAt,
  );

  /// Create a copy of CreateCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateCardPayloadImplCopyWith<_$CreateCardPayloadImpl> get copyWith =>
      __$$CreateCardPayloadImplCopyWithImpl<_$CreateCardPayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateCardPayloadImplToJson(this);
  }
}

abstract class _CreateCardPayload implements CreateCardPayload {
  const factory _CreateCardPayload({
    required final String stationId,
    required final double units,
    required final String pin,
    final String? recipientName,
    final String? recipientPhone,
    final DateTime? expiresAt,
  }) = _$CreateCardPayloadImpl;

  factory _CreateCardPayload.fromJson(Map<String, dynamic> json) =
      _$CreateCardPayloadImpl.fromJson;

  @override
  String get stationId;
  @override
  double get units;
  @override
  String get pin;
  @override
  String? get recipientName;
  @override
  String? get recipientPhone;
  @override
  DateTime? get expiresAt;

  /// Create a copy of CreateCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateCardPayloadImplCopyWith<_$CreateCardPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateCardResponse _$CreateCardResponseFromJson(Map<String, dynamic> json) {
  return _CreateCardResponse.fromJson(json);
}

/// @nodoc
mixin _$CreateCardResponse {
  String get cardId => throw _privateConstructorUsedError;
  String get cardNumber => throw _privateConstructorUsedError;
  String get pin => throw _privateConstructorUsedError;
  double get units => throw _privateConstructorUsedError;
  String? get qrCode => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this CreateCardResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateCardResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateCardResponseCopyWith<CreateCardResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateCardResponseCopyWith<$Res> {
  factory $CreateCardResponseCopyWith(
    CreateCardResponse value,
    $Res Function(CreateCardResponse) then,
  ) = _$CreateCardResponseCopyWithImpl<$Res, CreateCardResponse>;
  @useResult
  $Res call({
    String cardId,
    String cardNumber,
    String pin,
    double units,
    String? qrCode,
    String? message,
  });
}

/// @nodoc
class _$CreateCardResponseCopyWithImpl<$Res, $Val extends CreateCardResponse>
    implements $CreateCardResponseCopyWith<$Res> {
  _$CreateCardResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateCardResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? cardNumber = null,
    Object? pin = null,
    Object? units = null,
    Object? qrCode = freezed,
    Object? message = freezed,
  }) {
    return _then(
      _value.copyWith(
            cardId: null == cardId
                ? _value.cardId
                : cardId // ignore: cast_nullable_to_non_nullable
                      as String,
            cardNumber: null == cardNumber
                ? _value.cardNumber
                : cardNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            pin: null == pin
                ? _value.pin
                : pin // ignore: cast_nullable_to_non_nullable
                      as String,
            units: null == units
                ? _value.units
                : units // ignore: cast_nullable_to_non_nullable
                      as double,
            qrCode: freezed == qrCode
                ? _value.qrCode
                : qrCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateCardResponseImplCopyWith<$Res>
    implements $CreateCardResponseCopyWith<$Res> {
  factory _$$CreateCardResponseImplCopyWith(
    _$CreateCardResponseImpl value,
    $Res Function(_$CreateCardResponseImpl) then,
  ) = __$$CreateCardResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String cardId,
    String cardNumber,
    String pin,
    double units,
    String? qrCode,
    String? message,
  });
}

/// @nodoc
class __$$CreateCardResponseImplCopyWithImpl<$Res>
    extends _$CreateCardResponseCopyWithImpl<$Res, _$CreateCardResponseImpl>
    implements _$$CreateCardResponseImplCopyWith<$Res> {
  __$$CreateCardResponseImplCopyWithImpl(
    _$CreateCardResponseImpl _value,
    $Res Function(_$CreateCardResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateCardResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? cardNumber = null,
    Object? pin = null,
    Object? units = null,
    Object? qrCode = freezed,
    Object? message = freezed,
  }) {
    return _then(
      _$CreateCardResponseImpl(
        cardId: null == cardId
            ? _value.cardId
            : cardId // ignore: cast_nullable_to_non_nullable
                  as String,
        cardNumber: null == cardNumber
            ? _value.cardNumber
            : cardNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        pin: null == pin
            ? _value.pin
            : pin // ignore: cast_nullable_to_non_nullable
                  as String,
        units: null == units
            ? _value.units
            : units // ignore: cast_nullable_to_non_nullable
                  as double,
        qrCode: freezed == qrCode
            ? _value.qrCode
            : qrCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateCardResponseImpl implements _CreateCardResponse {
  const _$CreateCardResponseImpl({
    required this.cardId,
    required this.cardNumber,
    required this.pin,
    required this.units,
    this.qrCode,
    this.message,
  });

  factory _$CreateCardResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateCardResponseImplFromJson(json);

  @override
  final String cardId;
  @override
  final String cardNumber;
  @override
  final String pin;
  @override
  final double units;
  @override
  final String? qrCode;
  @override
  final String? message;

  @override
  String toString() {
    return 'CreateCardResponse(cardId: $cardId, cardNumber: $cardNumber, pin: $pin, units: $units, qrCode: $qrCode, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateCardResponseImpl &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.cardNumber, cardNumber) ||
                other.cardNumber == cardNumber) &&
            (identical(other.pin, pin) || other.pin == pin) &&
            (identical(other.units, units) || other.units == units) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, cardId, cardNumber, pin, units, qrCode, message);

  /// Create a copy of CreateCardResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateCardResponseImplCopyWith<_$CreateCardResponseImpl> get copyWith =>
      __$$CreateCardResponseImplCopyWithImpl<_$CreateCardResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateCardResponseImplToJson(this);
  }
}

abstract class _CreateCardResponse implements CreateCardResponse {
  const factory _CreateCardResponse({
    required final String cardId,
    required final String cardNumber,
    required final String pin,
    required final double units,
    final String? qrCode,
    final String? message,
  }) = _$CreateCardResponseImpl;

  factory _CreateCardResponse.fromJson(Map<String, dynamic> json) =
      _$CreateCardResponseImpl.fromJson;

  @override
  String get cardId;
  @override
  String get cardNumber;
  @override
  String get pin;
  @override
  double get units;
  @override
  String? get qrCode;
  @override
  String? get message;

  /// Create a copy of CreateCardResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateCardResponseImplCopyWith<_$CreateCardResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UseCardPayload _$UseCardPayloadFromJson(Map<String, dynamic> json) {
  return _UseCardPayload.fromJson(json);
}

/// @nodoc
mixin _$UseCardPayload {
  String get cardNumber => throw _privateConstructorUsedError;
  String get pin => throw _privateConstructorUsedError;

  /// Serializes this UseCardPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UseCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UseCardPayloadCopyWith<UseCardPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UseCardPayloadCopyWith<$Res> {
  factory $UseCardPayloadCopyWith(
    UseCardPayload value,
    $Res Function(UseCardPayload) then,
  ) = _$UseCardPayloadCopyWithImpl<$Res, UseCardPayload>;
  @useResult
  $Res call({String cardNumber, String pin});
}

/// @nodoc
class _$UseCardPayloadCopyWithImpl<$Res, $Val extends UseCardPayload>
    implements $UseCardPayloadCopyWith<$Res> {
  _$UseCardPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UseCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? cardNumber = null, Object? pin = null}) {
    return _then(
      _value.copyWith(
            cardNumber: null == cardNumber
                ? _value.cardNumber
                : cardNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            pin: null == pin
                ? _value.pin
                : pin // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UseCardPayloadImplCopyWith<$Res>
    implements $UseCardPayloadCopyWith<$Res> {
  factory _$$UseCardPayloadImplCopyWith(
    _$UseCardPayloadImpl value,
    $Res Function(_$UseCardPayloadImpl) then,
  ) = __$$UseCardPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String cardNumber, String pin});
}

/// @nodoc
class __$$UseCardPayloadImplCopyWithImpl<$Res>
    extends _$UseCardPayloadCopyWithImpl<$Res, _$UseCardPayloadImpl>
    implements _$$UseCardPayloadImplCopyWith<$Res> {
  __$$UseCardPayloadImplCopyWithImpl(
    _$UseCardPayloadImpl _value,
    $Res Function(_$UseCardPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UseCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? cardNumber = null, Object? pin = null}) {
    return _then(
      _$UseCardPayloadImpl(
        cardNumber: null == cardNumber
            ? _value.cardNumber
            : cardNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        pin: null == pin
            ? _value.pin
            : pin // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UseCardPayloadImpl implements _UseCardPayload {
  const _$UseCardPayloadImpl({required this.cardNumber, required this.pin});

  factory _$UseCardPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$UseCardPayloadImplFromJson(json);

  @override
  final String cardNumber;
  @override
  final String pin;

  @override
  String toString() {
    return 'UseCardPayload(cardNumber: $cardNumber, pin: $pin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UseCardPayloadImpl &&
            (identical(other.cardNumber, cardNumber) ||
                other.cardNumber == cardNumber) &&
            (identical(other.pin, pin) || other.pin == pin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cardNumber, pin);

  /// Create a copy of UseCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UseCardPayloadImplCopyWith<_$UseCardPayloadImpl> get copyWith =>
      __$$UseCardPayloadImplCopyWithImpl<_$UseCardPayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UseCardPayloadImplToJson(this);
  }
}

abstract class _UseCardPayload implements UseCardPayload {
  const factory _UseCardPayload({
    required final String cardNumber,
    required final String pin,
  }) = _$UseCardPayloadImpl;

  factory _UseCardPayload.fromJson(Map<String, dynamic> json) =
      _$UseCardPayloadImpl.fromJson;

  @override
  String get cardNumber;
  @override
  String get pin;

  /// Create a copy of UseCardPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UseCardPayloadImplCopyWith<_$UseCardPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
