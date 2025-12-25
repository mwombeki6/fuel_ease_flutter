// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recharge_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RechargePayload _$RechargePayloadFromJson(Map<String, dynamic> json) {
  return _RechargePayload.fromJson(json);
}

/// @nodoc
mixin _$RechargePayload {
  int get amountTzs => throw _privateConstructorUsedError;
  String get msisdn => throw _privateConstructorUsedError;
  String get stationId => throw _privateConstructorUsedError;
  String? get provider => throw _privateConstructorUsedError;

  /// Serializes this RechargePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RechargePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RechargePayloadCopyWith<RechargePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RechargePayloadCopyWith<$Res> {
  factory $RechargePayloadCopyWith(
    RechargePayload value,
    $Res Function(RechargePayload) then,
  ) = _$RechargePayloadCopyWithImpl<$Res, RechargePayload>;
  @useResult
  $Res call({int amountTzs, String msisdn, String stationId, String? provider});
}

/// @nodoc
class _$RechargePayloadCopyWithImpl<$Res, $Val extends RechargePayload>
    implements $RechargePayloadCopyWith<$Res> {
  _$RechargePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RechargePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amountTzs = null,
    Object? msisdn = null,
    Object? stationId = null,
    Object? provider = freezed,
  }) {
    return _then(
      _value.copyWith(
            amountTzs: null == amountTzs
                ? _value.amountTzs
                : amountTzs // ignore: cast_nullable_to_non_nullable
                      as int,
            msisdn: null == msisdn
                ? _value.msisdn
                : msisdn // ignore: cast_nullable_to_non_nullable
                      as String,
            stationId: null == stationId
                ? _value.stationId
                : stationId // ignore: cast_nullable_to_non_nullable
                      as String,
            provider: freezed == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RechargePayloadImplCopyWith<$Res>
    implements $RechargePayloadCopyWith<$Res> {
  factory _$$RechargePayloadImplCopyWith(
    _$RechargePayloadImpl value,
    $Res Function(_$RechargePayloadImpl) then,
  ) = __$$RechargePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int amountTzs, String msisdn, String stationId, String? provider});
}

/// @nodoc
class __$$RechargePayloadImplCopyWithImpl<$Res>
    extends _$RechargePayloadCopyWithImpl<$Res, _$RechargePayloadImpl>
    implements _$$RechargePayloadImplCopyWith<$Res> {
  __$$RechargePayloadImplCopyWithImpl(
    _$RechargePayloadImpl _value,
    $Res Function(_$RechargePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RechargePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amountTzs = null,
    Object? msisdn = null,
    Object? stationId = null,
    Object? provider = freezed,
  }) {
    return _then(
      _$RechargePayloadImpl(
        amountTzs: null == amountTzs
            ? _value.amountTzs
            : amountTzs // ignore: cast_nullable_to_non_nullable
                  as int,
        msisdn: null == msisdn
            ? _value.msisdn
            : msisdn // ignore: cast_nullable_to_non_nullable
                  as String,
        stationId: null == stationId
            ? _value.stationId
            : stationId // ignore: cast_nullable_to_non_nullable
                  as String,
        provider: freezed == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RechargePayloadImpl implements _RechargePayload {
  const _$RechargePayloadImpl({
    required this.amountTzs,
    required this.msisdn,
    required this.stationId,
    this.provider,
  });

  factory _$RechargePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$RechargePayloadImplFromJson(json);

  @override
  final int amountTzs;
  @override
  final String msisdn;
  @override
  final String stationId;
  @override
  final String? provider;

  @override
  String toString() {
    return 'RechargePayload(amountTzs: $amountTzs, msisdn: $msisdn, stationId: $stationId, provider: $provider)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RechargePayloadImpl &&
            (identical(other.amountTzs, amountTzs) ||
                other.amountTzs == amountTzs) &&
            (identical(other.msisdn, msisdn) || other.msisdn == msisdn) &&
            (identical(other.stationId, stationId) ||
                other.stationId == stationId) &&
            (identical(other.provider, provider) ||
                other.provider == provider));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, amountTzs, msisdn, stationId, provider);

  /// Create a copy of RechargePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RechargePayloadImplCopyWith<_$RechargePayloadImpl> get copyWith =>
      __$$RechargePayloadImplCopyWithImpl<_$RechargePayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RechargePayloadImplToJson(this);
  }
}

abstract class _RechargePayload implements RechargePayload {
  const factory _RechargePayload({
    required final int amountTzs,
    required final String msisdn,
    required final String stationId,
    final String? provider,
  }) = _$RechargePayloadImpl;

  factory _RechargePayload.fromJson(Map<String, dynamic> json) =
      _$RechargePayloadImpl.fromJson;

  @override
  int get amountTzs;
  @override
  String get msisdn;
  @override
  String get stationId;
  @override
  String? get provider;

  /// Create a copy of RechargePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RechargePayloadImplCopyWith<_$RechargePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RechargeResponse _$RechargeResponseFromJson(Map<String, dynamic> json) {
  return _RechargeResponse.fromJson(json);
}

/// @nodoc
mixin _$RechargeResponse {
  String get transactionId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get reference => throw _privateConstructorUsedError;

  /// Serializes this RechargeResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RechargeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RechargeResponseCopyWith<RechargeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RechargeResponseCopyWith<$Res> {
  factory $RechargeResponseCopyWith(
    RechargeResponse value,
    $Res Function(RechargeResponse) then,
  ) = _$RechargeResponseCopyWithImpl<$Res, RechargeResponse>;
  @useResult
  $Res call({
    String transactionId,
    String status,
    String? message,
    String? reference,
  });
}

/// @nodoc
class _$RechargeResponseCopyWithImpl<$Res, $Val extends RechargeResponse>
    implements $RechargeResponseCopyWith<$Res> {
  _$RechargeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RechargeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? status = null,
    Object? message = freezed,
    Object? reference = freezed,
  }) {
    return _then(
      _value.copyWith(
            transactionId: null == transactionId
                ? _value.transactionId
                : transactionId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            reference: freezed == reference
                ? _value.reference
                : reference // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RechargeResponseImplCopyWith<$Res>
    implements $RechargeResponseCopyWith<$Res> {
  factory _$$RechargeResponseImplCopyWith(
    _$RechargeResponseImpl value,
    $Res Function(_$RechargeResponseImpl) then,
  ) = __$$RechargeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String transactionId,
    String status,
    String? message,
    String? reference,
  });
}

/// @nodoc
class __$$RechargeResponseImplCopyWithImpl<$Res>
    extends _$RechargeResponseCopyWithImpl<$Res, _$RechargeResponseImpl>
    implements _$$RechargeResponseImplCopyWith<$Res> {
  __$$RechargeResponseImplCopyWithImpl(
    _$RechargeResponseImpl _value,
    $Res Function(_$RechargeResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RechargeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? status = null,
    Object? message = freezed,
    Object? reference = freezed,
  }) {
    return _then(
      _$RechargeResponseImpl(
        transactionId: null == transactionId
            ? _value.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        reference: freezed == reference
            ? _value.reference
            : reference // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RechargeResponseImpl implements _RechargeResponse {
  const _$RechargeResponseImpl({
    required this.transactionId,
    required this.status,
    this.message,
    this.reference,
  });

  factory _$RechargeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RechargeResponseImplFromJson(json);

  @override
  final String transactionId;
  @override
  final String status;
  @override
  final String? message;
  @override
  final String? reference;

  @override
  String toString() {
    return 'RechargeResponse(transactionId: $transactionId, status: $status, message: $message, reference: $reference)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RechargeResponseImpl &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.reference, reference) ||
                other.reference == reference));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, transactionId, status, message, reference);

  /// Create a copy of RechargeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RechargeResponseImplCopyWith<_$RechargeResponseImpl> get copyWith =>
      __$$RechargeResponseImplCopyWithImpl<_$RechargeResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RechargeResponseImplToJson(this);
  }
}

abstract class _RechargeResponse implements RechargeResponse {
  const factory _RechargeResponse({
    required final String transactionId,
    required final String status,
    final String? message,
    final String? reference,
  }) = _$RechargeResponseImpl;

  factory _RechargeResponse.fromJson(Map<String, dynamic> json) =
      _$RechargeResponseImpl.fromJson;

  @override
  String get transactionId;
  @override
  String get status;
  @override
  String? get message;
  @override
  String? get reference;

  /// Create a copy of RechargeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RechargeResponseImplCopyWith<_$RechargeResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
