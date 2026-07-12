import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/stations/data/models/fuel_inventory_entry.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/pump.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_details_provider.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_pump_status_provider.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

class StationDetailsScreen extends ConsumerWidget {
  const StationDetailsScreen({
    required this.stationId,
    super.key,
  });

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(stationDetailsProvider(stationId));
    final pumpsAsync = ref.watch(stationPumpsProvider(stationId));
    final realtimeState = ref.watch(realtimePumpStatusProvider);
    final user = ref.watch(currentUserProvider);
    final canViewInventory = user?.isAdmin == true ||
        user?.isStationManager == true ||
        user?.isRegulator == true;
    final inventoryAsync = canViewInventory
        ? ref.watch(stationInventoryProvider(stationId))
        : const AsyncValue<List<FuelInventoryEntry>>.data([]);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Station Details'),
        elevation: 0,
      ),
      body: stationAsync.when(
        data: (station) {
          return RefreshIndicator(
            onRefresh: () async {
              final refreshes = <Future<void>>[
                ref.refresh(stationDetailsProvider(stationId).future),
                ref.refresh(stationPumpsProvider(stationId).future),
              ];
              if (canViewInventory) {
                refreshes.add(
                  ref.refresh(stationInventoryProvider(stationId).future),
                );
              }
              await Future.wait(refreshes);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StationHeader(
                  name: station.name,
                  status: station.status ?? 'UNKNOWN',
                  address: station.address,
                  district: station.district,
                  region: station.region,
                  contactNumber: station.contactNumber,
                  operatingHours: station.operatingHours,
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Fuel Inventory',
                  subtitle: 'Live storage levels by fuel type',
                ),
                if (canViewInventory)
                  inventoryAsync.when(
                    data: (items) => _InventoryGrid(items: items),
                    loading: () => const _SectionLoading(),
                    error: (error, _) => _SectionError(message: error.toString()),
                  )
                else
                  const _SectionInfo(
                    message: 'Inventory data is available to station staff only.',
                  ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Pumps',
                  subtitle: 'Operational status and fuel types',
                ),
                pumpsAsync.when(
                  data: (pumps) => _PumpList(
                    pumps: pumps,
                    realtime: realtimeState,
                    stationId: stationId,
                  ),
                  loading: () => const _SectionLoading(),
                  error: (error, _) => _SectionError(message: error.toString()),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load station: $error',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _StationHeader extends StatelessWidget {
  const _StationHeader({
    required this.name,
    required this.status,
    this.address,
    this.district,
    this.region,
    this.contactNumber,
    this.operatingHours,
  });

  final String name;
  final String status;
  final String? address;
  final String? district;
  final String? region;
  final String? contactNumber;
  final String? operatingHours;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(status, cs);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (address != null || district != null || region != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _joinAddress(address, district, region),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          if (contactNumber != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  contactNumber!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
          if (operatingHours != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    operatingHours!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _joinAddress(String? address, String? district, String? region) {
    final parts = <String>[];
    if (address != null && address.isNotEmpty) parts.add(address);
    if (district != null && district.isNotEmpty) parts.add(district);
    if (region != null && region.isNotEmpty) parts.add(region);
    return parts.join(', ');
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'MAINTENANCE':
        return AppColors.warning;
      case 'INACTIVE':
        return cs.onSurface.withValues(alpha: 0.7);
      default:
        return cs.onSurface.withValues(alpha: 0.7);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.titleMedium
                  .copyWith(color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  const _InventoryGrid({required this.items});

  final List<FuelInventoryEntry> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return const _EmptyState(message: 'No inventory data available.');
    }

    return Column(
      children: items.map((entry) {
        final percent = entry.percentFull.clamp(0, 100);
        final color = _fuelColor(entry.fuelType, cs);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.fuelType.toUpperCase(),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: color,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${NumberFormat('#,##0').format(entry.currentLevel)} / ${NumberFormat('#,##0').format(entry.capacity)} L',
                style: AppTextStyles.bodySmall.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (entry.lastRefill != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Last refill: ${entry.lastRefill}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _fuelColor(String fuelType, ColorScheme cs) {
    switch (fuelType.toUpperCase()) {
      case 'PETROL':
        return AppColors.petrolColor;
      case 'DIESEL':
        return AppColors.dieselColor;
      case 'PREMIUM':
        return AppColors.premiumColor;
      default:
        return cs.primary;
    }
  }
}

class _PumpList extends StatelessWidget {
  const _PumpList({
    required this.pumps,
    required this.realtime,
    required this.stationId,
  });

  final List<Pump> pumps;
  final PumpRealtimeState realtime;
  final String stationId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (pumps.isEmpty) {
      return const _EmptyState(message: 'No pumps available.');
    }

    return Column(
      children: pumps.map((pump) {
        final live = realtime.byPump[pump.id];
        final sameStation =
            live == null || live.stationId == null || live.stationId == stationId;
        final effectiveLive = sameStation ? live : null;
        final isLive = effectiveLive != null &&
            DateTime.now().difference(effectiveLive.receivedAt).inMinutes < 3;
        final status = effectiveLive?.status ?? pump.status;
        final statusColor = _statusColor(status, cs);
        final flowRate =
            effectiveLive?.data['flowRate'] ?? effectiveLive?.data['flow_rate'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_gas_station,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pump ${pump.pumpNumber}',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pump.fuelType.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (flowRate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Flow rate: ${flowRate.toString()} L/s',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'DISPENSING':
        return cs.secondary;
      case 'MAINTENANCE':
        return AppColors.warning;
      case 'DISABLED':
      case 'INACTIVE':
        return cs.onSurface.withValues(alpha: 0.7);
      default:
        return cs.onSurface.withValues(alpha: 0.7);
    }
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionInfo extends StatelessWidget {
  const _SectionInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
