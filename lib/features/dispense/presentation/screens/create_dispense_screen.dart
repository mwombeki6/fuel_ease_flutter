import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/glassmorphism.dart';

class CreateDispenseScreen extends ConsumerStatefulWidget {
  final String? preselectedStationId;

  const CreateDispenseScreen({super.key, this.preselectedStationId});

  @override
  ConsumerState<CreateDispenseScreen> createState() => _CreateDispenseScreenState();
}

class _CreateDispenseScreenState extends ConsumerState<CreateDispenseScreen> {
  int _step = 0; // 0 = Station, 1 = Fuel & Amount, 2 = Confirm
  String? _selectedStationId;
  String? _selectedFuelType;
  double _amount = 0;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStationId != null) {
      _selectedStationId = widget.preselectedStationId;
      _step = 1;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _selectedStationId == null) return;
    if (_step == 1 && (_selectedFuelType == null || _amount <= 0)) return;
    setState(() => _step++);
    HapticFeedback.lightImpact();
  }

  void _previousStep() {
    setState(() => _step--);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final stationState = ref.watch(stationSelectionProvider);

    final stations = stationState.stations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Fuel Request',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          _step == 0
                              ? 'Step 1 of 3 • Choose Station'
                              : _step == 1
                                  ? 'Step 2 of 3 • Fuel & Amount'
                                  : 'Step 3 of 3 • Confirm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${_step + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _step;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (index < 2) const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

            // Step Content
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: PageController(initialPage: _step),
                onPageChanged: (page) => setState(() => _step = page),
                children: [
                  // Step 1: Select Station
                  _StationStep(
                    stations: stations,
                    selectedId: _selectedStationId,
                    onSelect: (id) {
                      setState(() {
                        _selectedStationId = id;
                      });
                    },
                    onNext: _nextStep,
                    canProceed: _selectedStationId != null,
                  ),

                  // Step 2: Fuel Type & Amount
                  _FuelAmountStep(
                    onFuelSelect: (fuel) {
                      setState(() => _selectedFuelType = fuel);
                    },
                    onAmountChanged: (amount) {
                      setState(() => _amount = amount);
                    },
                    selectedFuelType: _selectedFuelType,
                    amount: _amount,
                    onNext: _nextStep,
                    onBack: _previousStep,
                    canProceed: _selectedFuelType != null && _amount > 0,
                  ),

                  // Step 3: Confirm
                  _ConfirmStep(
                    station: stations
                        .where((s) => s.id == _selectedStationId)
                        .firstOrNull,
                    fuelType: _selectedFuelType!,
                    amount: _amount,
                    onBack: _previousStep,
                    onConfirm: () {
                      // TODO: Create dispense request
                      context.push(Routes.createDispensingRequest);
                    },
                  ),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: GlassButton(
                        variant: GlassButtonVariant.ghost,
                        onPressed: _previousStep,
                        leadingIcon: Icons.arrow_back_rounded,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      variant: _step == 2 ? GlassButtonVariant.primary : GlassButtonVariant.primary,
                      onPressed: _step == 0 || _step == 1 ? _nextStep : () {
                        // Submit dispense request
                        // TODO: Call API
                        context.push('/fuel/live/dummy');
                      },
                      trailingIcon: _step == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      child: Text(_step == 2 ? 'Confirm & Pay' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 1: Station Selection
class _StationStep extends StatelessWidget {
  final List<dynamic> stations;
  final String? selectedId;
  final Function(String) onSelect;
  final VoidCallback onNext;
  final bool canProceed;

  const _StationStep({
    required this.stations,
    required this.selectedId,
    required this.onSelect,
    required this.onNext,
    required this.canProceed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Where will you fuel up?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a nearby station to continue',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final station = stations[index];
            final isSelected = station.id == selectedId;
            return GestureDetector(
              onTap: () => onSelect(station.id),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                onTap: () => onSelect(station.id),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: station.status == 'active'
                            ? LinearGradient(
                                colors: [
                                  AppColors.petrolColor.withValues(alpha: 0.2),
                                  AppColors.petrolColor.withValues(alpha: 0.1),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.15),
                                  Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.05),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.local_gas_station_rounded,
                        color: station.status == 'active'
                            ? AppColors.petrolColor
                            : Theme.of(context).colorScheme.outline,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Sora',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${station.district}, ${station.region}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 2.5,
                        ),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                            : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Step 2.5: Confirmation
class _ConfirmStep extends StatelessWidget {
  final Station? station;
  final String fuelType;
  final double amount;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _ConfirmStep({
    required this.station,
    required this.fuelType,
    required this.amount,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Confirm Details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your fuel request before confirming',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _ConfirmRow(
                label: 'Station',
                value: station?.name ?? 'Unknown station',
                icon: Icons.local_gas_station_rounded,
              ),
              const Divider(height: 24),
              _ConfirmRow(
                label: 'Fuel Type',
                value: fuelType,
                icon: Icons.oil_barrel_rounded,
              ),
              const Divider(height: 24),
              _ConfirmRow(
                label: 'Amount',
                value: '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)} L',
                icon: Icons.speed_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GlassButton(
                variant: GlassButtonVariant.ghost,
                onPressed: onBack,
                leadingIcon: Icons.arrow_back_rounded,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                variant: GlassButtonVariant.primary,
                onPressed: onConfirm,
                trailingIcon: Icons.check_rounded,
                child: const Text('Confirm & Pay'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ConfirmRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Sora',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Step 2: Fuel Type & Amount
class _FuelAmountStep extends StatelessWidget {
  final Function(String) onFuelSelect;
  final Function(double) onAmountChanged;
  final String? selectedFuelType;
  final double amount;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool canProceed;

  const _FuelAmountStep({
    required this.onFuelSelect,
    required this.onAmountChanged,
    required this.selectedFuelType,
    required this.amount,
    required this.onNext,
    required this.onBack,
    required this.canProceed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fuel Type & Amount',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select fuel type and enter amount in liters',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Fuel Types
          Text(
            'Fuel Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FuelTypeCard(
                  label: 'Petrol',
                  icon: Icons.local_gas_station_rounded,
                  gradient: AppColors.petrolGradientLight,
                  selected: selectedFuelType == 'petrol',
                  onTap: () => onFuelSelect('petrol'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FuelTypeCard(
                  label: 'Diesel',
                  icon: Icons.local_gas_station_rounded,
                  gradient: AppColors.dieselGradientLight,
                  selected: selectedFuelType == 'diesel',
                  onTap: () => onFuelSelect('diesel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FuelTypeCard(
                  label: 'Premium',
                  icon: Icons.flash_on_rounded,
                  gradient: AppColors.premiumGradientLight,
                  selected: selectedFuelType == 'premium',
                  onTap: () => onFuelSelect('premium'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Amount Input
          Text(
            'Amount (Liters)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Sora',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liters',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                _NumberPad(onAmountChanged: onAmountChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final bool selected;
  final VoidCallback onTap;

  const _FuelTypeCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_gas_station_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Sora',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selected ? 'SELECTED' : 'TAP TO SELECT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final Function(double) onAmountChanged;

  const _NumberPad({required this.onAmountChanged});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '���'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: row.map((btn) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GlassButton(
                    variant: btn == '���'
                        ? GlassButtonVariant.ghost
                        : GlassButtonVariant.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // TODO: Implement number pad logic
                    },
                    child: Text(btn),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}