import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/data/repositories/cards_repository.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Create card screen — select a fuel company and optionally set an expiry date.
class CreateCardScreen extends ConsumerStatefulWidget {
  const CreateCardScreen({super.key});

  @override
  ConsumerState<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends ConsumerState<CreateCardScreen> {
  bool _isLoading = false;
  bool _loadingCompanies = true;

  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId;
  DateTime? _selectedExpiry;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies =
          await ref.read(cardsRepositoryProvider).getCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
          _loadingCompanies = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCompanies = false);
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _selectedExpiry = date);
  }

  Future<void> _handleCreateCard() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fuel company')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(cardsProvider.notifier).createCard(
            companyId: _selectedCompanyId!,
            expiresAt: _selectedExpiry,
          );

      if (mounted && response.card.cvv != null) {
        await _showCvvDialog(response.card.last4, response.card.cvv!);
      }

      if (mounted) {
        if (response.card.status == 'pending') {
          context.pushReplacement(Routes.cardPending(response.card.id));
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create card: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCvvDialog(String last4, String cvv) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Your CVV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your card CVV is shown below. Save it now — it will never be shown again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Card ending ****$last4',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cvv,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 8,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("I've saved it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Fuel Card'), elevation: 0),
      body: _loadingCompanies
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Company picker
                const Text(
                  'Fuel Company',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _companies.isEmpty
                    ? const Text('No companies available',
                        style: TextStyle(color: AppColors.textSecondary))
                    : DropdownButtonFormField<String>(
                        value: _selectedCompanyId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'Select a company',
                        ),
                        items: _companies
                            .map((c) => DropdownMenuItem<String>(
                                  value: c['id'] as String,
                                  child: Text(c['name'] as String? ?? c['id'] as String),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCompanyId = v),
                      ),
                const SizedBox(height: 24),

                // Expiry date
                const Text(
                  'Expiry Date (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectExpiryDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _selectedExpiry != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedExpiry!)
                          : 'Default: 1 year from today',
                      style: TextStyle(
                        color: _selectedExpiry != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateCard,
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
                            'Create Card',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
