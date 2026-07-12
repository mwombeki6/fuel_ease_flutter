import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';

bool _isOpen(StationMapPin pin) => pin.status == 'active' && !pin.hasSuspension;

class StationSheet extends ConsumerStatefulWidget {
  const StationSheet({super.key});

  @override
  ConsumerState<StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends ConsumerState<StationSheet> {
  final _controller = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(nearestOrSelectedStationValueProvider);
    if (station == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.22,
      minChildSize: 0.22,
      maxChildSize: 0.6,
      snap: true,
      snapSizes: const [0.22, 0.6],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    station.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _isOpen(station) ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isOpen(station)
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${station.region} · ${station.district}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${station.activePumps} pumps available',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {}, // TODO(directions): wire to a maps deep-link once specced
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => context.push(
                        Routes.createDispensingRequest,
                        extra: station.id,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Start fueling'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
