import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class CreateDispenseScreen extends ConsumerStatefulWidget {
  const CreateDispenseScreen({super.key, this.preselectedStationId});

  final String? preselectedStationId;

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

  bool get _stationLocked => widget.preselectedStationId != null;

  static const _fuelTypes = ['petrol', 'diesel', 'premium', 'gas'];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStationId != null) {
      _selectedStationId = widget.preselectedStationId;
    }
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withValues(alpha: 0.8), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Dispense Fuel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance banner
            _DarkBalanceBanner(balanceTzs: balanceTzs)
                .animate()
                .slideY(begin: 0.2, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Card selection
            _SectionLabel('Select Card'),
            const SizedBox(height: 8),
            _DarkCardPicker(
              cards: activeCards,
              selectedCardId: _selectedCardId,
              onChanged: (id) => setState(() => _selectedCardId = id),
            )
                .animate(delay: 60.ms)
                .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 250.ms),

            const SizedBox(height: 24),

            // Station selection
            _SectionLabel('Select Station'),
            const SizedBox(height: 8),
            if (_stationLocked)
              _LockedStationRow(
                stationId: widget.preselectedStationId!,
                stations: stations,
                onEdit: () => context.go(Routes.map),
              )
            else
              _DarkStationPicker(
                stations: stations,
                selectedStationId: _selectedStationId,
                onChanged: (id) => setState(() => _selectedStationId = id),
              ),

            const SizedBox(height: 24),

            // Fuel type
            _SectionLabel('Fuel Type'),
            const SizedBox(height: 8),
            _DarkDropdown<String>(
              value: _selectedFuelType,
              items: _fuelTypes,
              itemLabel: (t) => t[0].toUpperCase() + t.substring(1),
              onChanged: (v) => setState(() => _selectedFuelType = v!),
            ),

            const SizedBox(height: 24),

            // Amount input
            _SectionLabel('Fuel Amount'),
            const SizedBox(height: 8),
            _DarkAmountField(controller: _litersController),

            const SizedBox(height: 36),

            GradientButton(
              onPressed: _isLoading ? null : _submit,
              label: 'Generate fuel code',
              isLoading: _isLoading,
            )
                .animate(delay: 200.ms)
                .slideY(begin: 0.3, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.55),
          letterSpacing: 0.4,
        ),
      );
}

// ── Dark balance banner ────────────────────────────────────────────────────

class _DarkBalanceBanner extends StatelessWidget {
  const _DarkBalanceBanner({required this.balanceTzs});
  final int balanceTzs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${NumberFormat('#,###').format(balanceTzs)} TZS',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dark card picker ───────────────────────────────────────────────────────

class _DarkCardPicker extends StatelessWidget {
  const _DarkCardPicker({
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
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Text(
          'No active cards. Create a card first.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        ),
      );
    }

    return _DarkDropdown<String>(
      value: selectedCardId,
      hint: 'Choose a card',
      items: cards.map((c) => c.id).toList(),
      itemLabel: (id) {
        final card = cards.firstWhere((c) => c.id == id, orElse: () => cards.first);
        return card.maskedCardNumber;
      },
      onChanged: onChanged,
      validator: (v) => v == null ? 'Select a card' : null,
    );
  }
}

// ── Dark station picker ────────────────────────────────────────────────────

class _DarkStationPicker extends StatelessWidget {
  const _DarkStationPicker({
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
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Text(
          'No stations available.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        ),
      );
    }

    return _DarkDropdown<String>(
      value: selectedStationId,
      hint: 'Choose a station',
      items: stations.map((s) => s.id).toList(),
      itemLabel: (id) {
        final station = stations.firstWhere((s) => s.id == id, orElse: () => stations.first);
        return station.name;
      },
      onChanged: onChanged,
      validator: (v) => v == null ? 'Select a station' : null,
    );
  }
}

// ── Dark dropdown ─────────────────────────────────────────────────────────

class _DarkDropdown<T> extends StatelessWidget {
  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: colorScheme.surfaceContainerHighest,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      iconEnabledColor: Colors.white.withValues(alpha: 0.4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// ── Locked station row ─────────────────────────────────────────────────────

class _LockedStationRow extends StatelessWidget {
  const _LockedStationRow({
    required this.stationId,
    required this.stations,
    required this.onEdit,
  });

  final String stationId;
  final List<Station> stations;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = stations
        .where((s) => s.id == stationId)
        .map((s) => s.name)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name ?? stationId,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined, size: 16, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// ── Dark amount input ──────────────────────────────────────────────────────

class _DarkAmountField extends StatelessWidget {
  const _DarkAmountField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Liters',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        hintText: '10.00',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        suffixText: 'L',
        suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter liters';
        final val = double.tryParse(v);
        if (val == null || val <= 0) return 'Enter a valid amount';
        return null;
      },
    );
  }
}
