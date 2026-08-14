import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/create_dispense_response.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
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
  int _step = 0; // 0 = Card, 1 = Station, 2 = Fuel & Amount, 3 = Confirm
  String? _selectedCardId;
  String? _selectedStationId;
  String? _selectedFuelType;
  double _amount = 0;
  bool _isLoading = false;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStationId != null) {
      _selectedStationId = widget.preselectedStationId;
      _step = _step + 1;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _selectedCardId == null) return;
    if (_step == 1 && _selectedStationId == null) return;
    if (_step == 2 && (_selectedFuelType == null || _amount <= 0)) return;
    setState(() => _step++);
    HapticFeedback.lightImpact();
  }

  void _previousStep() {
    setState(() => _step--);
    HapticFeedback.lightImpact();
  }

  Future<void> _submit() async {
    if (_selectedCardId == null) {
      _showError('Please select a card');
      return;
    }
    if (_selectedStationId == null) {
      _showError('Please select a station');
      return;
    }
    if (_selectedFuelType == null || _amount <= 0) {
      _showError('Please set a fuel type and amount');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = CreateDispensePayload(
        cardId: _selectedCardId!,
        stationId: _selectedStationId!,
        fuelType: _selectedFuelType!,
        requestedLiters: _amount,
      );

      final response = await ref
          .read(dispenseProvider.notifier)
          .createRequest(payload);

      if (mounted) {
        context.push(
          Routes.dispensingRequest(response.request.id),
          extra: response,
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(cardsProvider);
    final stationState = ref.watch(stationSelectionProvider);

    final activeCards =
        cardsState.whenOrNull(
          data: (cards) => cards.where((c) => c.isActive).toList(),
        ) ??
        [];

    final stations = stationState.stations
        .where((s) => s.status == null || s.status == 'active')
        .toList();

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
                              ? 'Step 1 of 4 • Choose Card'
                              : _step == 1
                                  ? 'Step 2 of 4 • Choose Station'
                                  : _step == 2
                                      ? 'Step 3 of 4 • Fuel & Amount'
                                      : 'Step 4 of 4 • Confirm',
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
                children: List.generate(4, (index) {
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
                        if (index < 3) const SizedBox(width: 8),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Step Content
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _step = page),
                children: [
                  // Step 0: Select Card
                  _CardStep(
                    cards: activeCards,
                    selectedId: _selectedCardId,
                    onSelect: (id) {
                      setState(() {
                        _selectedCardId = id;
                      });
                    },
                    onNext: _nextStep,
                    canProceed: _selectedCardId != null,
                  ),

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
                    card: activeCards
                        .where((c) => c.id == _selectedCardId)
                        .firstOrNull,
                    station: stations
                        .where((s) => s.id == _selectedStationId)
                        .firstOrNull,
                    fuelType: _selectedFuelType ?? '',
                    amount: _amount,
                    isLoading: _isLoading,
                    onBack: _previousStep,
                    onConfirm: _submit,
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
                        onPressed: _isLoading ? () {} : _previousStep,
                        leadingIcon: Icons.arrow_back_rounded,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.primary,
                      onPressed: _isLoading
                          ? () {}
                          : _step == 3
                              ? _submit
                              : _nextStep,
                      loading: _isLoading,
                      trailingIcon:
                          _step == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      child: Text(_step == 3 ? 'Confirm & Pay' : 'Continue'),
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

// Step 0: Card Selection
class _CardStep extends StatelessWidget {
  final List<FuelCard> cards;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  final bool canProceed;

  const _CardStep({
    required this.cards,
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
          'Which card will you use?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select an active card to fund the request',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        if (cards.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active cards',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Sora',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a card first to dispense fuel.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                GlassButton(
                  variant: GlassButtonVariant.primary,
                  onPressed: () => context.push(Routes.createCard),
                  trailingIcon: Icons.add_rounded,
                  child: const Text('Create Card'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final card = cards[index];
              final isSelected = card.id == selectedId;
              return GlassCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                onTap: () => onSelect(card.id),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.petrolColor.withValues(alpha: 0.2),
                            AppColors.petrolColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: AppColors.petrolColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.maskedCardNumber,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Sora',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expires ${card.expiresAt.year}-${card.expiresAt.month.toString().padLeft(2, '0')}',
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
              );
            },
          ),
      ],
    );
  }
}

// Step 1: Station Selection
class _StationStep extends StatelessWidget {
  final List<Station> stations;
  final String? selectedId;
  final ValueChanged<String> onSelect;
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
        if (stations.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No stations available.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final station = stations[index];
              final isSelected = station.id == selectedId;
              return GlassCard(
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
              );
            },
          ),
      ],
    );
  }
}

// Step 3: Confirmation
class _ConfirmStep extends StatelessWidget {
  final FuelCard? card;
  final Station? station;
  final String fuelType;
  final double amount;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _ConfirmStep({
    required this.card,
    required this.station,
    required this.fuelType,
    required this.amount,
    required this.isLoading,
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
                label: 'Card',
                value: card?.maskedCardNumber ?? 'No card selected',
                icon: Icons.credit_card_rounded,
              ),
              const Divider(height: 24),
              _ConfirmRow(
                label: 'Station',
                value: station?.name ?? 'Unknown station',
                icon: Icons.local_gas_station_rounded,
              ),
              const Divider(height: 24),
              _ConfirmRow(
                label: 'Fuel Type',
                value: fuelType.isEmpty ? 'Not set' : fuelType.toUpperCase(),
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
                onPressed: isLoading ? () {} : onBack,
                leadingIcon: Icons.arrow_back_rounded,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                variant: GlassButtonVariant.primary,
                onPressed: isLoading ? () {} : onConfirm,
                loading: isLoading,
                trailingIcon: Icons.check_rounded,
                child: Text(isLoading ? 'Submitting…' : 'Confirm & Pay'),
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
  final ValueChanged<String> onFuelSelect;
  final ValueChanged<double> onAmountChanged;
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
                  amount <= 0
                      ? '0'
                      : amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2),
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

class _NumberPad extends StatefulWidget {
  final ValueChanged<double> onAmountChanged;

  const _NumberPad({required this.onAmountChanged});

  @override
  State<_NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<_NumberPad> {
  String _value = '';

  void _handleKey(String key) {
    setState(() {
      if (key == 'del') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      } else if (key == '.') {
        if (_value.isEmpty) {
          _value = '0.';
        } else if (!_value.contains('.')) {
          _value += '.';
        }
      } else {
        if (_value == '0') {
          _value = key;
        } else {
          _value += key;
        }
      }
      widget.onAmountChanged(double.tryParse(_value) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'del'],
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
                    variant: btn == 'del'
                        ? GlassButtonVariant.ghost
                        : GlassButtonVariant.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _handleKey(btn);
                    },
                    child: Text(btn == 'del' ? '⌫' : btn),
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
