import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Create card screen for creating new fuel cards
class CreateCardScreen extends ConsumerStatefulWidget {
  const CreateCardScreen({super.key});

  @override
  ConsumerState<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends ConsumerState<CreateCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _pinController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();

  DateTime? _selectedExpiry;
  bool _isLoading = false;

  // Quick unit options in liters
  final List<double> _quickUnits = [10, 20, 50, 100, 200];

  @override
  void dispose() {
    _unitsController.dispose();
    _pinController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final units = double.parse(_unitsController.text);
      final pin = _pinController.text.trim();

      // TODO: Get station ID from user's preferred station or selection
      const stationId = 'temp-station-id';

      final response = await ref.read(cardsProvider.notifier).createCard(
            stationId: stationId,
            units: units,
            pin: pin,
            recipientName: _recipientNameController.text.trim().isEmpty
                ? null
                : _recipientNameController.text.trim(),
            recipientPhone: _recipientPhoneController.text.trim().isEmpty
                ? null
                : _recipientPhoneController.text.trim(),
            expiresAt: _selectedExpiry,
          );

      if (mounted) {
        // Show success dialog with card details
        await showDialog(
          context: context,
          builder: (context) => _SuccessDialog(
            cardNumber: response.cardNumber,
            pin: response.pin,
            units: units,
          ),
        );

        // Navigate back after dialog closes
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create card: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectQuickUnits(double units) {
    _unitsController.text = units.toString();
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: maxDate,
    );

    if (date != null) {
      setState(() => _selectedExpiry = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Fuel Card'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create a digital fuel card to share fuel with others. The recipient can use the card number and PIN to redeem the fuel.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fuel units section
            const Text(
              'Fuel Units (Liters)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Quick unit buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickUnits.map((units) {
                return _QuickUnitChip(
                  units: units,
                  onTap: () => _selectQuickUnits(units),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Units input
            TextFormField(
              controller: _unitsController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Enter units',
                hintText: '50.00',
                suffixText: 'L',
                suffixStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter fuel units';
                }
                final units = double.tryParse(value);
                if (units == null || units <= 0) {
                  return 'Please enter a valid amount';
                }
                if (units < 1) {
                  return 'Minimum units is 1 liter';
                }
                if (units > 1000) {
                  return 'Maximum units is 1000 liters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // PIN section
            const Text(
              'Security PIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: '4-digit PIN',
                hintText: '1234',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a PIN';
                }
                if (value.length != 4) {
                  return 'PIN must be exactly 4 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Optional section
            const Text(
              'Optional Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Recipient name
            TextFormField(
              controller: _recipientNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Recipient Name',
                hintText: 'John Doe',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recipient phone
            TextFormField(
              controller: _recipientPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Recipient Phone',
                hintText: '0712345678',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expiry date
            InkWell(
              onTap: _selectExpiryDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expiry Date (Optional)',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedExpiry != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedExpiry!)
                      : 'No expiry',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedExpiry != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        'Create Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick unit selection chip
class _QuickUnitChip extends StatelessWidget {
  const _QuickUnitChip({
    required this.units,
    required this.onTap,
  });

  final double units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${units.toInt()} L',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Success dialog showing created card details
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.cardNumber,
    required this.pin,
    required this.units,
  });

  final String cardNumber;
  final String pin;
  final double units;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 48,
        ),
      ),
      title: const Text('Card Created Successfully!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your fuel card has been created. Share these details with the recipient:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _DetailRow(label: 'Card Number', value: cardNumber),
          const SizedBox(height: 12),
          _DetailRow(label: 'PIN', value: pin),
          const SizedBox(height: 12),
          _DetailRow(label: 'Units', value: '${units.toStringAsFixed(2)} L'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(text: 'Card: $cardNumber\nPIN: $pin'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Card details copied to clipboard'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text('Copy Details'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
