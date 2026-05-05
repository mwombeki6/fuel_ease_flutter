import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Wallet recharge screen for M-Pesa/AzamPay top-up
class RechargeScreen extends ConsumerStatefulWidget {
  const RechargeScreen({super.key});

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedProvider = 'Mpesa';
  bool _isLoading = false;

  // Predefined amount options in TZS
  final List<int> _quickAmounts = [5000, 10000, 20000, 50000, 100000];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRecharge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amountTzs = int.parse(_amountController.text.replaceAll(',', ''));
      final msisdn = _phoneController.text.trim();

      await ref.read(walletProvider.notifier).recharge(
            amountTzs: amountTzs,
            msisdn: msisdn,
            provider: _selectedProvider,
          );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recharge initiated! Check your phone for payment prompt.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recharge failed: ${e.toString()}'),
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

  void _selectQuickAmount(int amount) {
    _amountController.text = NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
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
                      'You will receive a payment prompt on your phone. Complete the payment to add fuel units to your wallet.',
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

            // Amount section
            const Text(
              'Amount (TZS)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                return _QuickAmountChip(
                  amount: amount,
                  onTap: () => _selectQuickAmount(amount),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Amount input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Enter amount',
                hintText: '10,000',
                prefixText: 'TZS ',
                prefixStyle: const TextStyle(
                  color: AppColors.textPrimary,
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
                  return 'Please enter an amount';
                }
                final amount = int.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount < 1000) {
                  return 'Minimum amount is TZS 1,000';
                }
                if (amount > 1000000) {
                  return 'Maximum amount is TZS 1,000,000';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Phone number section
            const Text(
              'Mobile Money Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '0712345678',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                if (!value.startsWith('0')) {
                  return 'Phone number must start with 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Payment provider section
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _PaymentProviderSelector(
              selectedProvider: _selectedProvider,
              onProviderChanged: (provider) {
                setState(() => _selectedProvider = provider);
              },
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRecharge,
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
                        'Proceed to Payment',
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

/// Quick amount selection chip
class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.onTap,
  });

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

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
          numberFormat.format(amount),
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

/// Payment provider selector (M-Pesa / AzamPay)
class _PaymentProviderSelector extends StatelessWidget {
  const _PaymentProviderSelector({
    required this.selectedProvider,
    required this.onProviderChanged,
  });

  final String selectedProvider;
  final ValueChanged<String> onProviderChanged;

  @override
  Widget build(BuildContext context) {
    const providers = [
      ('Mpesa', 'M-Pesa', Icons.phone_android),
      ('Tigopesa', 'Tigo Pesa', Icons.phone_android),
      ('Airtel', 'Airtel', Icons.phone_android),
      ('Halopesa', 'HaloPesa', Icons.account_balance_wallet),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: providers.map((p) {
        return _ProviderOption(
          provider: p.$1,
          label: p.$2,
          icon: p.$3,
          isSelected: selectedProvider == p.$1,
          onTap: () => onProviderChanged(p.$1),
        );
      }).toList(),
    );
  }
}

class _ProviderOption extends StatelessWidget {
  const _ProviderOption({
    required this.provider,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String provider;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Input formatter for thousands separator
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
