// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletSummaryImpl _$$WalletSummaryImplFromJson(Map json) => $checkedCreate(
  r'_$WalletSummaryImpl',
  json,
  ($checkedConvert) {
    final val = _$WalletSummaryImpl(
      wallet: $checkedConvert(
        'wallet',
        (v) => Wallet.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
      totalTransactions: $checkedConvert(
        'total_transactions',
        (v) => (v as num?)?.toInt(),
      ),
      totalSpent: $checkedConvert(
        'total_spent',
        (v) => (v as num?)?.toDouble(),
      ),
      totalRecharged: $checkedConvert(
        'total_recharged',
        (v) => (v as num?)?.toDouble(),
      ),
      recentTransactions: $checkedConvert(
        'recent_transactions',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => WalletTransaction.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      ),
      activeSessions: $checkedConvert(
        'active_sessions',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => FuelSession.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'totalTransactions': 'total_transactions',
    'totalSpent': 'total_spent',
    'totalRecharged': 'total_recharged',
    'recentTransactions': 'recent_transactions',
    'activeSessions': 'active_sessions',
  },
);

Map<String, dynamic> _$$WalletSummaryImplToJson(
  _$WalletSummaryImpl instance,
) => <String, dynamic>{
  'wallet': instance.wallet.toJson(),
  if (instance.totalTransactions case final value?) 'total_transactions': value,
  if (instance.totalSpent case final value?) 'total_spent': value,
  if (instance.totalRecharged case final value?) 'total_recharged': value,
  if (instance.recentTransactions?.map((e) => e.toJson()).toList()
      case final value?)
    'recent_transactions': value,
  if (instance.activeSessions?.map((e) => e.toJson()).toList()
      case final value?)
    'active_sessions': value,
};
