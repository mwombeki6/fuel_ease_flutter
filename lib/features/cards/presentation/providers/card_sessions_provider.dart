import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';

/// All dispense sessions for [cardId], sorted most-recent first.
final cardSessionsProvider =
    Provider.family<List<DispenseRequest>, String>((ref, cardId) {
  final dispenseState = ref.watch(dispenseProvider);
  return dispenseState.whenOrNull(data: (requests) {
    final filtered = requests.where((r) => r.cardId == cardId).toList();
    if (filtered.isEmpty) return const [];
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }) ?? const [];
});
