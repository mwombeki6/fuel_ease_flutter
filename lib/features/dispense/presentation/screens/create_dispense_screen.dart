import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/create_dispense_response.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class CreateDispenseScreen extends ConsumerStatefulWidget {
  const CreateDispenseScreen({super.key});

  @override
  ConsumerState<CreateDispenseScreen> createState() =>
      _CreateDispenseScreenState();
}

class _CreateDispenseScreenState extends ConsumerState<CreateDispenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();

  String? _selectedCardId;
  String? _selectedStationId;
  String _selectedFuelType = 'petrol';
  bool _isLoading = false;

  static const _fuelTypes = ['petrol', 'diesel', 'premium', 'gas'];

  @override
  void dispose() {
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCardId == null) {
      _showError('Please select a card');
      return;
    }
    if (_selectedStationId == null) {
      _showError('Please select a station');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = CreateDispensePayload(
        cardId: _selectedCardId!,
        stationId: _selectedStationId!,
        fuelType: _selectedFuelType,
        requestedLiters: double.parse(_litersController.text),
      );

      final response =
          await ref.read(dispenseProvider.notifier).createRequest(payload);

      if (mounted) {
        context.push(
          Routes.dispensingToken(response.request.id),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(cardsProvider);
    final stationState = ref.watch(stationSelectionProvider);
    final walletState = ref.watch(walletProvider);

    final activeCards = cardsState.whenOrNull(
          data: (cards) => cards.where((c) => c.isActive).toList(),
        ) ??
        [];

    final stations = stationState.stations
        .where((s) => s.status == null || s.status == 'active')
        .toList();

    final balanceTzs = walletState.whenOrNull(
          data: (summary) => summary.wallet.balanceTzs,
        ) ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dispense Fuel'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Wallet balance indicator
            _BalanceBanner(balanceTzs: balanceTzs),
            const SizedBox(height: 24),

            // Card selection
            const _SectionLabel('Select Card'),
            const SizedBox(height: 8),
            _CardPicker(
              cards: activeCards,
              selectedCardId: _selectedCardId,
              onChanged: (id) => setState(() => _selectedCardId = id),
            ),
            const SizedBox(height: 24),

            // Station selection
            const _SectionLabel('Select Station'),
            const SizedBox(height: 8),
            _StationPicker(
              stations: stations,
              selectedStationId: _selectedStationId,
              onChanged: (id) => setState(() => _selectedStationId = id),
            ),
            const SizedBox(height: 24),

            // Fuel type selection
            const _SectionLabel('Fuel Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFuelType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _fuelTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                            t[0].toUpperCase() + t.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFuelType = v!),
            ),
            const SizedBox(height: 24),

            // Amount input
            const _SectionLabel('Fuel Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _litersController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Liters',
                hintText: '10.00',
                suffixText: 'L',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter liters';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Generate PIN & QR Code',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({required this.balanceTzs});
  final int balanceTzs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${NumberFormat('#,###').format(balanceTzs)} TZS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPicker extends StatelessWidget {
  const _CardPicker({
    required this.cards,
    required this.selectedCardId,
    required this.onChanged,
  });

  final List<FuelCard> cards;
  final String? selectedCardId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No active cards. Create a card first.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedCardId,
      decoration: InputDecoration(
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: const Text('Choose a card'),
      items: cards
          .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.maskedCardNumber),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Select a card' : null,
    );
  }
}

class _StationPicker extends StatelessWidget {
  const _StationPicker({
    required this.stations,
    required this.selectedStationId,
    required this.onChanged,
  });

  final List<Station> stations;
  final String? selectedStationId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No stations available.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedStationId,
      isExpanded: true,
      decoration: InputDecoration(
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: const Text('Choose a station'),
      items: stations
          .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(
                  s.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Select a station' : null,
    );
  }
}

