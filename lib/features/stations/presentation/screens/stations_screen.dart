import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

class StationsScreen extends ConsumerStatefulWidget {
  const StationsScreen({super.key});

  @override
  ConsumerState<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends ConsumerState<StationsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationState = ref.watch(stationSelectionProvider);

    final stations = stationState.stations.where((station) {
      if (_query.isEmpty) return true;
      final target =
          '${station.name} ${station.district ?? ''} ${station.region ?? ''}'
              .toLowerCase();
      return target.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map view',
            onPressed: () => context.push(Routes.stationMap),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(stationSelectionProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (stationState.isRefreshing) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Search stations…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (stationState.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      stationState.fromCache ? Icons.cloud_off : Icons.cloud_done,
                      size: 16,
                      color: AppColors.textSecondaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stationState.fromCache
                            ? 'Showing cached data'
                            : 'Updated ${DateFormat('MMM d, HH:mm').format(stationState.lastUpdated!)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (stationState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                          stationState.error ?? 'Failed to load stations',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (stationState.isLoading)
              const _StationsLoading()
            else if (stations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No stations found',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              )
            else
              ...stations.map((station) {
                final selected = station.id == stationState.stationId;
                final subtitleParts = [
                  if (station.district != null && station.district!.isNotEmpty)
                    station.district!,
                  if (station.region != null && station.region!.isNotEmpty)
                    station.region!,
                ];
                final subtitle = subtitleParts.join(', ');

                final cs = Theme.of(context).colorScheme;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: selected ? cs.primary : Colors.transparent,
                        width: 3,
                      ),
                      top: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                      right: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                      bottom: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_gas_station_rounded,
                      color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                    ),
                    title: Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    subtitle: subtitle.isEmpty
                        ? null
                        : Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          Icon(Icons.check_circle_rounded, color: cs.primary),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          color: cs.onSurface.withValues(alpha: 0.4),
                          onPressed: () {
                            ref
                                .read(stationSelectionProvider.notifier)
                                .setStation(station);
                            context.push(Routes.stationDetails(station.id));
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      await ref
                          .read(stationSelectionProvider.notifier)
                          .setStation(station);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Selected ${station.name}'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        navigator.pop();
                      }
                    },
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.map),
        icon: const Icon(Icons.map_rounded),
        label: const Text('Open Map'),
      ),
    );
  }
}

class _StationsLoading extends StatelessWidget {
  const _StationsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            height: 78,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 12,
                          width: 160,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 10,
                          width: 120,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
