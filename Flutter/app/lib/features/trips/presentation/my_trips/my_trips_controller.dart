import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trips_repository.dart';
import '../../domain/trip.dart';

final myTripsControllerProvider =
    StateNotifierProvider<MyTripsController, AsyncValue<MyTripsState>>((ref) {
      return MyTripsController(ref.watch(tripsRepositoryProvider));
    });

class MyTripsState {
  final String searchQuery;
  final bool showUpcomingOnly;
  final List<Trip> trips;

  const MyTripsState({
    this.searchQuery = '',
    this.showUpcomingOnly = true,
    required this.trips,
  });

  List<Trip> get filteredTrips {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final baseTrips = showUpcomingOnly
        ? trips.where((trip) => trip.isUpcoming)
        : trips;

    if (normalizedQuery.isEmpty) {
      return baseTrips.toList();
    }

    return baseTrips.where((trip) {
      return trip.airline.toLowerCase().contains(normalizedQuery) ||
          trip.fromCode.toLowerCase().contains(normalizedQuery) ||
          trip.fromCity.toLowerCase().contains(normalizedQuery) ||
          trip.toCode.toLowerCase().contains(normalizedQuery) ||
          trip.toCity.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  MyTripsState copyWith({
    String? searchQuery,
    bool? showUpcomingOnly,
    List<Trip>? trips,
  }) {
    return MyTripsState(
      searchQuery: searchQuery ?? this.searchQuery,
      showUpcomingOnly: showUpcomingOnly ?? this.showUpcomingOnly,
      trips: trips ?? this.trips,
    );
  }
}

class MyTripsController extends StateNotifier<AsyncValue<MyTripsState>> {
  final TripsRepository _repository;

  MyTripsController(this._repository) : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    final result = await _repository.getMyTrips();
    state = result.when(
      success: (trips) => AsyncValue.data(
        MyTripsState(
          searchQuery: current?.searchQuery ?? '',
          showUpcomingOnly: current?.showUpcomingOnly ?? true,
          trips: trips,
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
}
