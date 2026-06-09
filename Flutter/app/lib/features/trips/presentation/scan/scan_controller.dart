import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trips_repository.dart';
import '../../domain/trip.dart';

final scanControllerProvider =
    StateNotifierProvider<ScanController, AsyncValue<Trip?>>((ref) {
      return ScanController(ref.watch(tripsRepositoryProvider));
    });

class ScanController extends StateNotifier<AsyncValue<Trip?>> {
  final TripsRepository _repository;

  ScanController(this._repository) : super(const AsyncValue.data(null));

  Future<Trip?> scanPayload(String payload) async {
    final normalized = payload.trim();
    if (normalized.isEmpty) {
      state = AsyncValue.error(
        'Ticket QR payload is empty.',
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncValue.loading();
    final result = await _repository.scanQr(normalized);
    return result.when(
      success: (trip) {
        state = AsyncValue.data(trip);
        return trip;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }

  Future<Trip?> scanImage(String imagePath) async {
    state = const AsyncValue.loading();
    final result = await _repository.scanTicketImage(imagePath);
    return result.when(
      success: (trip) {
        state = AsyncValue.data(trip);
        return trip;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }
}
