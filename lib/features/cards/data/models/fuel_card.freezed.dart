// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FuelCard _$FuelCardFromJson(Map<String, dynamic> json) {
  return _FuelCard.fromJson(json);
}

/// @nodoc
mixin _$FuelCard {
  String get id => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get stationId => throw _privateConstructorUsedError;
  double get units => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get cardNumber => throw _privateConstructorUsedError;
  String? get pin => throw _privateConstructorUsedError;
  String? get stationName => throw _privateConstructorUsedError;
  String? get recipientName => throw _privateConstructorUsedError;
  String? get recipientPhone => throw _privateConstructorUsedError;
  String? get usedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  DateTime? get usedAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this FuelCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FuelCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FuelCardCopyWith<FuelCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FuelCardCopyWith<$Res> {
  factory $FuelCardCopyWith(FuelCard value, $Res Function(FuelCard) then) =
      _$FuelCardCopyWithImpl<$Res, FuelCard>;
  @useResult
  $Res call({
    String id,
    String customerId,
    String stationId,
    double units,
    String status,
    String cardNumber,
    String? pin,
    String? stationName,
    String? recipientName,
    String? recipientPhone,
    String? usedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$FuelCardCopyWithImpl<$Res, $Val extends FuelCard>
    implements $FuelCardCopyWith<$Res> {
  _$FuelCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FuelCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? stationId = null,
    Object? units = null,
    Object? status = null,
    Object? cardNumber = null,
    Object? pin = freezed,
    Object? stationName = freezed,
    Object? recipientName = freezed,
    Object? recipientPhone = freezed,
    Object? usedBy = freezed,
    Object? createdAt = freezed,
    Object? expiresAt = freezed,
    Object? usedAt = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            stationId: null == stationId
                ? _value.stationId
                : stationId // ignore: cast_nullable_to_non_nullable
                      as String,
            units: null == units
                ? _value.units
                : units // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            cardNumber: null == cardNumber
                ? _value.cardNumber
                : cardNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            pin: freezed == pin
                ? _value.pin
                : pin // ignore: cast_nullable_to_non_nullable
                      as String?,
            stationName: freezed == stationName
                ? _value.stationName
                : stationName // ignore: cast_nullable_to_non_nullable
                      as String?,
            recipientName: freezed == recipientName
                ? _value.recipientName
                : recipientName // ignore: cast_nullable_to_non_nullable
                      as String?,
            recipientPhone: freezed == recipientPhone
                ? _value.recipientPhone
                : recipientPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            usedBy: freezed == usedBy
                ? _value.usedBy
                : usedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            usedAt: freezed == usedAt
                ? _value.usedAt
                : usedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FuelCardImplCopyWith<$Res>
    implements $FuelCardCopyWith<$Res> {
  factory _$$FuelCardImplCopyWith(
    _$FuelCardImpl value,
    $Res Function(_$FuelCardImpl) then,
  ) = __$$FuelCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String customerId,
    String stationId,
    double units,
    String status,
    String cardNumber,
    String? pin,
    String? stationName,
    String? recipientName,
    String? recipientPhone,
    String? usedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$FuelCardImplCopyWithImpl<$Res>
    extends _$FuelCardCopyWithImpl<$Res, _$FuelCardImpl>
    implements _$$FuelCardImplCopyWith<$Res> {
  __$$FuelCardImplCopyWithImpl(
    _$FuelCardImpl _value,
    $Res Function(_$FuelCardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FuelCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? stationId = null,
    Object? units = null,
    Object? status = null,
    Object? cardNumber = null,
    Object? pin = freezed,
    Object? stationName = freezed,
    Object? recipientName = freezed,
    Object? recipientPhone = freezed,
    Object? usedBy = freezed,
    Object? createdAt = freezed,
    Object? expiresAt = freezed,
    Object? usedAt = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$FuelCardImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        stationId: null == stationId
            ? _value.stationId
            : stationId // ignore: cast_nullable_to_non_nullable
                  as String,
        units: null == units
            ? _value.units
            : units // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        cardNumber: null == cardNumber
            ? _value.cardNumber
            : cardNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        pin: freezed == pin
            ? _value.pin
            : pin // ignore: cast_nullable_to_non_nullable
                  as String?,
        stationName: freezed == stationName
            ? _value.stationName
            : stationName // ignore: cast_nullable_to_non_nullable
                  as String?,
        recipientName: freezed == recipientName
            ? _value.recipientName
            : recipientName // ignore: cast_nullable_to_non_nullable
                  as String?,
        recipientPhone: freezed == recipientPhone
            ? _value.recipientPhone
            : recipientPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        usedBy: freezed == usedBy
            ? _value.usedBy
            : usedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        usedAt: freezed == usedAt
            ? _value.usedAt
            : usedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FuelCardImpl extends _FuelCard {
  const _$FuelCardImpl({
    required this.id,
    required this.customerId,
    required this.stationId,
    required this.units,
    required this.status,
    required this.cardNumber,
    this.pin,
    this.stationName,
    this.recipientName,
    this.recipientPhone,
    this.usedBy,
    this.createdAt,
    this.expiresAt,
    this.usedAt,
    final Map<String, dynamic>? metadata,
  }) : _metadata = metadata,
       super._();

  factory _$FuelCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$FuelCardImplFromJson(json);

  @override
  final String id;
  @override
  final String customerId;
  @override
  final String stationId;
  @override
  final double units;
  @override
  final String status;
  @override
  final String cardNumber;
  @override
  final String? pin;
  @override
  final String? stationName;
  @override
  final String? recipientName;
  @override
  final String? recipientPhone;
  @override
  final String? usedBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? expiresAt;
  @override
  final DateTime? usedAt;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'FuelCard(id: $id, customerId: $customerId, stationId: $stationId, units: $units, status: $status, cardNumber: $cardNumber, pin: $pin, stationName: $stationName, recipientName: $recipientName, recipientPhone: $recipientPhone, usedBy: $usedBy, createdAt: $createdAt, expiresAt: $expiresAt, usedAt: $usedAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FuelCardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.stationId, stationId) ||
                other.stationId == stationId) &&
            (identical(other.units, units) || other.units == units) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.cardNumber, cardNumber) ||
                other.cardNumber == cardNumber) &&
            (identical(other.pin, pin) || other.pin == pin) &&
            (identical(other.stationName, stationName) ||
                other.stationName == stationName) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.recipientPhone, recipientPhone) ||
                other.recipientPhone == recipientPhone) &&
            (identical(other.usedBy, usedBy) || other.usedBy == usedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    customerId,
    stationId,
    units,
    status,
    cardNumber,
    pin,
    stationName,
    recipientName,
    recipientPhone,
    usedBy,
    createdAt,
    expiresAt,
    usedAt,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of FuelCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FuelCardImplCopyWith<_$FuelCardImpl> get copyWith =>
      __$$FuelCardImplCopyWithImpl<_$FuelCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FuelCardImplToJson(this);
  }
}

abstract class _FuelCard extends FuelCard {
  const factory _FuelCard({
    required final String id,
    required final String customerId,
    required final String stationId,
    required final double units,
    required final String status,
    required final String cardNumber,
    final String? pin,
    final String? stationName,
    final String? recipientName,
    final String? recipientPhone,
    final String? usedBy,
    final DateTime? createdAt,
    final DateTime? expiresAt,
    final DateTime? usedAt,
    final Map<String, dynamic>? metadata,
  }) = _$FuelCardImpl;
  const _FuelCard._() : super._();

  factory _FuelCard.fromJson(Map<String, dynamic> json) =
      _$FuelCardImpl.fromJson;

  @override
  String get id;
  @override
  String get customerId;
  @override
  String get stationId;
  @override
  double get units;
  @override
  String get status;
  @override
  String get cardNumber;
  @override
  String? get pin;
  @override
  String? get stationName;
  @override
  String? get recipientName;
  @override
  String? get recipientPhone;
  @override
  String? get usedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get expiresAt;
  @override
  DateTime? get usedAt;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of FuelCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FuelCardImplCopyWith<_$FuelCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
