// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WalletSummary _$WalletSummaryFromJson(Map<String, dynamic> json) {
  return _WalletSummary.fromJson(json);
}

/// @nodoc
mixin _$WalletSummary {
  Wallet get wallet => throw _privateConstructorUsedError;
  int? get totalTransactions => throw _privateConstructorUsedError;
  double? get totalSpent => throw _privateConstructorUsedError;
  double? get totalRecharged => throw _privateConstructorUsedError;
  List<WalletTransaction>? get recentTransactions =>
      throw _privateConstructorUsedError;
  List<FuelSession>? get activeSessions => throw _privateConstructorUsedError;

  /// Serializes this WalletSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletSummaryCopyWith<WalletSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletSummaryCopyWith<$Res> {
  factory $WalletSummaryCopyWith(
    WalletSummary value,
    $Res Function(WalletSummary) then,
  ) = _$WalletSummaryCopyWithImpl<$Res, WalletSummary>;
  @useResult
  $Res call({
    Wallet wallet,
    int? totalTransactions,
    double? totalSpent,
    double? totalRecharged,
    List<WalletTransaction>? recentTransactions,
    List<FuelSession>? activeSessions,
  });

  $WalletCopyWith<$Res> get wallet;
}

/// @nodoc
class _$WalletSummaryCopyWithImpl<$Res, $Val extends WalletSummary>
    implements $WalletSummaryCopyWith<$Res> {
  _$WalletSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wallet = null,
    Object? totalTransactions = freezed,
    Object? totalSpent = freezed,
    Object? totalRecharged = freezed,
    Object? recentTransactions = freezed,
    Object? activeSessions = freezed,
  }) {
    return _then(
      _value.copyWith(
            wallet: null == wallet
                ? _value.wallet
                : wallet // ignore: cast_nullable_to_non_nullable
                      as Wallet,
            totalTransactions: freezed == totalTransactions
                ? _value.totalTransactions
                : totalTransactions // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalSpent: freezed == totalSpent
                ? _value.totalSpent
                : totalSpent // ignore: cast_nullable_to_non_nullable
                      as double?,
            totalRecharged: freezed == totalRecharged
                ? _value.totalRecharged
                : totalRecharged // ignore: cast_nullable_to_non_nullable
                      as double?,
            recentTransactions: freezed == recentTransactions
                ? _value.recentTransactions
                : recentTransactions // ignore: cast_nullable_to_non_nullable
                      as List<WalletTransaction>?,
            activeSessions: freezed == activeSessions
                ? _value.activeSessions
                : activeSessions // ignore: cast_nullable_to_non_nullable
                      as List<FuelSession>?,
          )
          as $Val,
    );
  }

  /// Create a copy of WalletSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletCopyWith<$Res> get wallet {
    return $WalletCopyWith<$Res>(_value.wallet, (value) {
      return _then(_value.copyWith(wallet: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WalletSummaryImplCopyWith<$Res>
    implements $WalletSummaryCopyWith<$Res> {
  factory _$$WalletSummaryImplCopyWith(
    _$WalletSummaryImpl value,
    $Res Function(_$WalletSummaryImpl) then,
  ) = __$$WalletSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Wallet wallet,
    int? totalTransactions,
    double? totalSpent,
    double? totalRecharged,
    List<WalletTransaction>? recentTransactions,
    List<FuelSession>? activeSessions,
  });

  @override
  $WalletCopyWith<$Res> get wallet;
}

/// @nodoc
class __$$WalletSummaryImplCopyWithImpl<$Res>
    extends _$WalletSummaryCopyWithImpl<$Res, _$WalletSummaryImpl>
    implements _$$WalletSummaryImplCopyWith<$Res> {
  __$$WalletSummaryImplCopyWithImpl(
    _$WalletSummaryImpl _value,
    $Res Function(_$WalletSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WalletSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wallet = null,
    Object? totalTransactions = freezed,
    Object? totalSpent = freezed,
    Object? totalRecharged = freezed,
    Object? recentTransactions = freezed,
    Object? activeSessions = freezed,
  }) {
    return _then(
      _$WalletSummaryImpl(
        wallet: null == wallet
            ? _value.wallet
            : wallet // ignore: cast_nullable_to_non_nullable
                  as Wallet,
        totalTransactions: freezed == totalTransactions
            ? _value.totalTransactions
            : totalTransactions // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalSpent: freezed == totalSpent
            ? _value.totalSpent
            : totalSpent // ignore: cast_nullable_to_non_nullable
                  as double?,
        totalRecharged: freezed == totalRecharged
            ? _value.totalRecharged
            : totalRecharged // ignore: cast_nullable_to_non_nullable
                  as double?,
        recentTransactions: freezed == recentTransactions
            ? _value._recentTransactions
            : recentTransactions // ignore: cast_nullable_to_non_nullable
                  as List<WalletTransaction>?,
        activeSessions: freezed == activeSessions
            ? _value._activeSessions
            : activeSessions // ignore: cast_nullable_to_non_nullable
                  as List<FuelSession>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletSummaryImpl implements _WalletSummary {
  const _$WalletSummaryImpl({
    required this.wallet,
    this.totalTransactions,
    this.totalSpent,
    this.totalRecharged,
    final List<WalletTransaction>? recentTransactions,
    final List<FuelSession>? activeSessions,
  }) : _recentTransactions = recentTransactions,
       _activeSessions = activeSessions;

  factory _$WalletSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletSummaryImplFromJson(json);

  @override
  final Wallet wallet;
  @override
  final int? totalTransactions;
  @override
  final double? totalSpent;
  @override
  final double? totalRecharged;
  final List<WalletTransaction>? _recentTransactions;
  @override
  List<WalletTransaction>? get recentTransactions {
    final value = _recentTransactions;
    if (value == null) return null;
    if (_recentTransactions is EqualUnmodifiableListView)
      return _recentTransactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<FuelSession>? _activeSessions;
  @override
  List<FuelSession>? get activeSessions {
    final value = _activeSessions;
    if (value == null) return null;
    if (_activeSessions is EqualUnmodifiableListView) return _activeSessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'WalletSummary(wallet: $wallet, totalTransactions: $totalTransactions, totalSpent: $totalSpent, totalRecharged: $totalRecharged, recentTransactions: $recentTransactions, activeSessions: $activeSessions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletSummaryImpl &&
            (identical(other.wallet, wallet) || other.wallet == wallet) &&
            (identical(other.totalTransactions, totalTransactions) ||
                other.totalTransactions == totalTransactions) &&
            (identical(other.totalSpent, totalSpent) ||
                other.totalSpent == totalSpent) &&
            (identical(other.totalRecharged, totalRecharged) ||
                other.totalRecharged == totalRecharged) &&
            const DeepCollectionEquality().equals(
              other._recentTransactions,
              _recentTransactions,
            ) &&
            const DeepCollectionEquality().equals(
              other._activeSessions,
              _activeSessions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    wallet,
    totalTransactions,
    totalSpent,
    totalRecharged,
    const DeepCollectionEquality().hash(_recentTransactions),
    const DeepCollectionEquality().hash(_activeSessions),
  );

  /// Create a copy of WalletSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletSummaryImplCopyWith<_$WalletSummaryImpl> get copyWith =>
      __$$WalletSummaryImplCopyWithImpl<_$WalletSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletSummaryImplToJson(this);
  }
}

abstract class _WalletSummary implements WalletSummary {
  const factory _WalletSummary({
    required final Wallet wallet,
    final int? totalTransactions,
    final double? totalSpent,
    final double? totalRecharged,
    final List<WalletTransaction>? recentTransactions,
    final List<FuelSession>? activeSessions,
  }) = _$WalletSummaryImpl;

  factory _WalletSummary.fromJson(Map<String, dynamic> json) =
      _$WalletSummaryImpl.fromJson;

  @override
  Wallet get wallet;
  @override
  int? get totalTransactions;
  @override
  double? get totalSpent;
  @override
  double? get totalRecharged;
  @override
  List<WalletTransaction>? get recentTransactions;
  @override
  List<FuelSession>? get activeSessions;

  /// Create a copy of WalletSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletSummaryImplCopyWith<_$WalletSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
