import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/deleted_trips_store.dart';
import '../../data/trips_repository.dart';
import '../../domain/trip.dart';

final myTripsControllerProvider =
    StateNotifierProvider.autoDispose<MyTripsController, AsyncValue<MyTripsState>>((ref) {
      return MyTripsController(
        ref.watch(tripsRepositoryProvider),
        DeletedTripsStore(),
      );
    });

final deletedTripsProvider =
    FutureProvider.autoDispose<List<DeletedTripEntry>>((ref) async {
      ref.watch(myTripsControllerProvider);
      return DeletedTripsStore().load();
    });

class MyTripsState {
  final String searchQuery;
  final bool showUpcomingOnly;
  final List<Trip> trips;
  final Set<int> deletedReservationIds;

  const MyTripsState({
    this.searchQuery = '',
    this.showUpcomingOnly = true,
    required this.trips,
    this.deletedReservationIds = const {},
  });

  List<Trip> get filteredTrips {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final baseTrips = trips.where(
      (trip) => !deletedReservationIds.contains(trip.reservationId),
    );

    // Upcoming tab keeps expired confirmed trips visible (shaded), not hidden.
    final tabTrips = showUpcomingOnly
        ? baseTrips.where((trip) => trip.status == TripStatus.confirmed)
        : baseTrips;

    final sorted = _sortTrips(tabTrips);

    if (normalizedQuery.isEmpty) {
      return sorted;
    }

    return sorted.where((trip) {
      return trip.airline.toLowerCase().contains(normalizedQuery) ||
          trip.fromCode.toLowerCase().contains(normalizedQuery) ||
          trip.fromCity.toLowerCase().contains(normalizedQuery) ||
          trip.toCode.toLowerCase().contains(normalizedQuery) ||
          trip.toCity.toLowerCase().contains(normalizedQuery) ||
          trip.flightNumber.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  static List<Trip> _sortTrips(Iterable<Trip> trips) {
    final list = trips.toList();
    list.sort((a, b) {
      final aUpcoming = a.isUpcoming;
      final bUpcoming = b.isUpcoming;
      if (aUpcoming != bUpcoming) {
        return aUpcoming ? -1 : 1;
      }

      final aDep = a.departureAt;
      final bDep = b.departureAt;
      if (aDep == null && bDep == null) {
        return 0;
      }
      if (aDep == null) {
        return 1;
      }
      if (bDep == null) {
        return -1;
      }

      if (a.isExpired && b.isExpired) {
        return bDep.compareTo(aDep);
      }

      return aDep.compareTo(bDep);
    });
    return list;
  }

  MyTripsState copyWith({
    String? searchQuery,
    bool? showUpcomingOnly,
    List<Trip>? trips,
    Set<int>? deletedReservationIds,
  }) {
    return MyTripsState(
      searchQuery: searchQuery ?? this.searchQuery,
      showUpcomingOnly: showUpcomingOnly ?? this.showUpcomingOnly,
      trips: trips ?? this.trips,
      deletedReservationIds:
          deletedReservationIds ?? this.deletedReservationIds,
    );
  }
}

class MyTripsController extends StateNotifier<AsyncValue<MyTripsState>> {
  final TripsRepository _repository;
  final DeletedTripsStore _deletedTripsStore;

  MyTripsController(this._repository, this._deletedTripsStore)
    : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    final deletedIds = await _deletedTripsStore.loadDeletedIds();
    final result = await _repository.getMyTrips();
    state = result.when(
      success: (trips) => AsyncValue.data(
        MyTripsState(
          searchQuery: current?.searchQuery ?? '',
          showUpcomingOnly: current?.showUpcomingOnly ?? true,
          trips: trips,
          deletedReservationIds: deletedIds,
        ),
      ),
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
  }

  void updateSearchQuery(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(searchQuery: value));
  }

  void showUpcoming() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(showUpcomingOnly: true));
  }

  void showAll() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(showUpcomingOnly: false));
  }

  Future<void> softDeleteTrip(Trip trip) async {
    await _deletedTripsStore.softDelete(trip);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        deletedReservationIds: {
          ...current.deletedReservationIds,
          trip.reservationId,
        },
      ),
    );
  }

  Future<void> restoreTrip(int reservationId) async {
    await _deletedTripsStore.restore(reservationId);
    final current = state.valueOrNull;
    if (current == null) return;
    final updatedDeleted = Set<int>.from(current.deletedReservationIds)
      ..remove(reservationId);
    state = AsyncValue.data(
      current.copyWith(deletedReservationIds: updatedDeleted),
    );
  }

  Future<void> permanentlyDeleteTrip(int reservationId) async {
    await _deletedTripsStore.permanentDelete(reservationId);
  }
}
