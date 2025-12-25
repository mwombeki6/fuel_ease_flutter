// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FuelSession _$FuelSessionFromJson(Map<String, dynamic> json) {
  return _FuelSession.fromJson(json);
}

/// @nodoc
mixin _$FuelSession {
  String get id => throw _privateConstructorUsedError;
  String get walletId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get stationId => throw _privateConstructorUsedError;
  double get unitsHeld => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get pumpId => throw _privateConstructorUsedError;
  String? get qrCode => throw _privateConstructorUsedError;
  String? get numericToken => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this FuelSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FuelSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FuelSessionCopyWith<FuelSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FuelSessionCopyWith<$Res> {
  factory $FuelSessionCopyWith(
    FuelSession value,
    $Res Function(FuelSession) then,
  ) = _$FuelSessionCopyWithImpl<$Res, FuelSession>;
  @useResult
  $Res call({
    String id,
    String walletId,
    String customerId,
    String stationId,
    double unitsHeld,
    String status,
    String? pumpId,
    String? qrCode,
    String? numericToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class _$FuelSessionCopyWithImpl<$Res, $Val extends FuelSession>
    implements $FuelSessionCopyWith<$Res> {
  _$FuelSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FuelSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? walletId = null,
    Object? customerId = null,
    Object? stationId = null,
    Object? unitsHeld = null,
    Object? status = null,
    Object? pumpId = freezed,
    Object? qrCode = freezed,
    Object? numericToken = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            walletId: null == walletId
                ? _value.walletId
                : walletId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            stationId: null == stationId
                ? _value.stationId
                : stationId // ignore: cast_nullable_to_non_nullable
                      as String,
            unitsHeld: null == unitsHeld
                ? _value.unitsHeld
                : unitsHeld // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            pumpId: freezed == pumpId
                ? _value.pumpId
                : pumpId // ignore: cast_nullable_to_non_nullable
                      as String?,
            qrCode: freezed == qrCode
                ? _value.qrCode
                : qrCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            numericToken: freezed == numericToken
                ? _value.numericToken
                : numericToken // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FuelSessionImplCopyWith<$Res>
    implements $FuelSessionCopyWith<$Res> {
  factory _$$FuelSessionImplCopyWith(
    _$FuelSessionImpl value,
    $Res Function(_$FuelSessionImpl) then,
  ) = __$$FuelSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String walletId,
    String customerId,
    String stationId,
    double unitsHeld,
    String status,
    String? pumpId,
    String? qrCode,
    String? numericToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class __$$FuelSessionImplCopyWithImpl<$Res>
    extends _$FuelSessionCopyWithImpl<$Res, _$FuelSessionImpl>
    implements _$$FuelSessionImplCopyWith<$Res> {
  __$$FuelSessionImplCopyWithImpl(
    _$FuelSessionImpl _value,
    $Res Function(_$FuelSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FuelSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? walletId = null,
    Object? customerId = null,
    Object? stationId = null,
    Object? unitsHeld = null,
    Object? status = null,
    Object? pumpId = freezed,
    Object? qrCode = freezed,
    Object? numericToken = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$FuelSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        walletId: null == walletId
            ? _value.walletId
            : walletId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        stationId: null == stationId
            ? _value.stationId
            : stationId // ignore: cast_nullable_to_non_nullable
                  as String,
        unitsHeld: null == unitsHeld
            ? _value.unitsHeld
            : unitsHeld // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        pumpId: freezed == pumpId
            ? _value.pumpId
            : pumpId // ignore: cast_nullable_to_non_nullable
                  as String?,
        qrCode: freezed == qrCode
            ? _value.qrCode
            : qrCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        numericToken: freezed == numericToken
            ? _value.numericToken
            : numericToken // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FuelSessionImpl extends _FuelSession {
  const _$FuelSessionImpl({
    required this.id,
    required this.walletId,
    required this.customerId,
    required this.stationId,
    required this.unitsHeld,
    required this.status,
    this.pumpId,
    this.qrCode,
    this.numericToken,
    this.expiresAt,
    this.createdAt,
    this.completedAt,
  }) : super._();

  factory _$FuelSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FuelSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String walletId;
  @override
  final String customerId;
  @override
  final String stationId;
  @override
  final double unitsHeld;
  @override
  final String status;
  @override
  final String? pumpId;
  @override
  final String? qrCode;
  @override
  final String? numericToken;
  @override
  final DateTime? expiresAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'FuelSession(id: $id, walletId: $walletId, customerId: $customerId, stationId: $stationId, unitsHeld: $unitsHeld, status: $status, pumpId: $pumpId, qrCode: $qrCode, numericToken: $numericToken, expiresAt: $expiresAt, createdAt: $createdAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FuelSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.walletId, walletId) ||
                other.walletId == walletId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.stationId, stationId) ||
                other.stationId == stationId) &&
            (identical(other.unitsHeld, unitsHeld) ||
                other.unitsHeld == unitsHeld) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pumpId, pumpId) || other.pumpId == pumpId) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.numericToken, numericToken) ||
                other.numericToken == numericToken) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    walletId,
    customerId,
    stationId,
    unitsHeld,
    status,
    pumpId,
    qrCode,
    numericToken,
    expiresAt,
    createdAt,
    completedAt,
  );

  /// Create a copy of FuelSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FuelSessionImplCopyWith<_$FuelSessionImpl> get copyWith =>
      __$$FuelSessionImplCopyWithImpl<_$FuelSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FuelSessionImplToJson(this);
  }
}

abstract class _FuelSession extends FuelSession {
  const factory _FuelSession({
    required final String id,
    required final String walletId,
    required final String customerId,
    required final String stationId,
    required final double unitsHeld,
    required final String status,
    final String? pumpId,
    final String? qrCode,
    final String? numericToken,
    final DateTime? expiresAt,
    final DateTime? createdAt,
    final DateTime? completedAt,
  }) = _$FuelSessionImpl;
  const _FuelSession._() : super._();

  factory _FuelSession.fromJson(Map<String, dynamic> json) =
      _$FuelSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get walletId;
  @override
  String get customerId;
  @override
  String get stationId;
  @override
  double get unitsHeld;
  @override
  String get status;
  @override
  String? get pumpId;
  @override
  String? get qrCode;
  @override
  String? get numericToken;
  @override
  DateTime? get expiresAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get completedAt;

  /// Create a copy of FuelSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FuelSessionImplCopyWith<_$FuelSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
