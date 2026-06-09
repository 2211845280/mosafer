import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/home_address_controller.dart';
import '../../../core/services/home_address_store.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/trip_origin_resolver.dart';
import '../data/trips_repository.dart';

enum TripStage { home, onTheWay, airport }

class TripStageState {
  final TripStage stage;
  final Map<String, dynamic>? departurePlan;
  final Map<String, dynamic>? locationCheck;
  final Map<String, dynamic>? airportDashboard;
  final String? error;

  const TripStageState({
    this.stage = TripStage.home,
    this.departurePlan,
    this.locationCheck,
    this.airportDashboard,
    this.error,
  });

  TripStageState copyWith({
    TripStage? stage,
    Map<String, dynamic>? departurePlan,
    Map<String, dynamic>? locationCheck,
    Map<String, dynamic>? airportDashboard,
    String? error,
  }) {
    return TripStageState(
      stage: stage ?? this.stage,
      departurePlan: departurePlan ?? this.departurePlan,
      locationCheck: locationCheck ?? this.locationCheck,
      airportDashboard: airportDashboard ?? this.airportDashboard,
      error: error,
    );
  }
}

final tripStageControllerProvider =
    StateNotifierProvider<TripStageController, AsyncValue<TripStageState>>((
      ref,
    ) {
      return TripStageController(
        ref.watch(tripsRepositoryProvider),
        ref.watch(homeAddressStoreProvider),
      );
    });

class TripStageController extends StateNotifier<AsyncValue<TripStageState>> {
  final TripsRepository _repository;
  final HomeAddressStore _homeAddressStore;
  final LocationService _locationService = LocationService();

  TripStageController(this._repository, this._homeAddressStore)
    : super(const AsyncValue.data(TripStageState()));

  Future<void> refresh(int reservationId, {String mode = 'driving'}) async {
    state = const AsyncValue.loading();
    final home = await _homeAddressStore.load();
    final position = await _locationService.currentPosition();
    final resolved = TripOriginResolver.resolve(
      homeAddress: home,
      gpsPosition: position,
    );
    final lat = resolved.lat;
    final lng = resolved.lng;

    final planned = await _repository.getDeparturePlan(
      reservationId: reservationId,
      lat: lat,
      lng: lng,
      mode: mode,
    );
    final plannedData = planned.dataOrNull;
    final check = await _repository.locationCheck(
      reservationId: reservationId,
      lat: lat,
      lng: lng,
    );
    await check.when(
      success: (data) async {
        final atAirport = data['at_airport'] == true;
        if (atAirport) {
          final dashboard = await _repository.airportDashboard(
            reservationId: reservationId,
            lat: lat,
            lng: lng,
          );
          state = dashboard.when(
            success: (airportData) => AsyncValue.data(
              TripStageState(
                stage: TripStage.airport,
                locationCheck: data,
                airportDashboard: airportData,
              ),
            ),
            failure: (error) => AsyncValue.data(
              TripStageState(
                stage: TripStage.airport,
                locationCheck: data,
                error: error,
              ),
            ),
          );
          return;
        }

        state = AsyncValue.data(
          TripStageState(
            stage: (data['distance_km'] as num? ?? 99) < 20
                ? TripStage.onTheWay
                : TripStage.home,
            locationCheck: data,
            departurePlan:
                plannedData ?? data['departure_plan'] as Map<String, dynamic>?,
          ),
        );
      },
      failure: (error) async {
        state = AsyncValue.data(TripStageState(error: error));
      },
    );
  }
}
