import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/create_dispense_response.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/dispense_repository.dart';

class DispenseNotifier extends AsyncNotifier<List<DispenseRequest>> {
  @override
  Future<List<DispenseRequest>> build() =>
      ref.read(dispenseRepositoryProvider).getRequests();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(dispenseRepositoryProvider).getRequests());
  }

  Future<CreateDispenseResponse> createRequest(
      CreateDispensePayload payload) async {
    final response =
        await ref.read(dispenseRepositoryProvider).createRequest(payload);
    await refresh();
    return response;
  }

  Future<void> cancelRequest(String id) async {
    await ref.read(dispenseRepositoryProvider).cancelRequest(id);
    await refresh();
  }
}

final dispenseProvider =
    AsyncNotifierProvider<DispenseNotifier, List<DispenseRequest>>(
        DispenseNotifier.new);

/// Auto-dispose provider for polling a single request by ID.
final dispenseRequestByIdProvider =
    FutureProvider.autoDispose.family<DispenseRequest, String>((ref, id) {
  return ref.read(dispenseRepositoryProvider).getRequest(id);
});
