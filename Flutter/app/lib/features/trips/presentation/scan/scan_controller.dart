import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/qr_image_decoder.dart';
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
        'scan:invalid_ticket',
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncValue.loading();
    final result = await _repository.scanQr(normalized);
    return result.when<Future<Trip?>>(
      success: _claimTrip,
      failure: (error) async {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }

  Future<Trip?> scanImage(XFile image) async {
    state = const AsyncValue.loading();

    final qrPayload = await extractQrPayloadFromImage(image);
    if (qrPayload != null && qrPayload.trim().isNotEmpty) {
      final qrResult = await _repository.scanQr(qrPayload.trim());
      final tripFromQr = qrResult.dataOrNull;
      if (tripFromQr != null) {
        return _claimTrip(tripFromQr);
      }
    }

    final result = await _repository.scanTicketImage(image);
    return result.when<Future<Trip?>>(
      success: _claimTrip,
      failure: (error) async {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }

  Future<Trip?> _claimTrip(Trip trip) async {
    final ticketNumber = trip.ticketNumber?.trim();
    if (ticketNumber == null || ticketNumber.isEmpty) {
      state = AsyncValue.error('scan:invalid_ticket', StackTrace.current);
      return null;
    }

    final claimResult = await _repository.claimTicket(ticketNumber);
    return claimResult.when(
      success: (_) {
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
