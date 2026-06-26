import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_session_controller.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/profile_state.dart';
import '../../features/trips/data/trips_repository.dart';
import '../../features/trips/domain/ai_travel.dart';
import '../../features/trips/domain/trip.dart';
import '../../features/trips/presentation/active_trip_controller.dart';
import '../../../core/models/home_address.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/home_address_controller.dart';
import '../../../shared/models/result.dart';
import 'screenshot_fixtures.dart';

export 'screenshot_fixtures.dart' show kScreenshotMockTrip;

/// When true (via `--dart-define=SCREENSHOT_MODE=true`), the app boots with
/// mock auth/trip data so documentation screenshots can be captured without login.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

List<Override> screenshotModeOverrides() {
  return [
    authSessionControllerProvider.overrideWith(
      (ref) => _ScreenshotAuthSessionController(
        ref.watch(secureStorageProvider),
        ref.watch(apiClientProvider),
      ),
    ),
    activeTripProvider.overrideWith((ref) => kScreenshotMockTrip),
    tripsRepositoryProvider.overrideWith(
      (ref) => _ScreenshotTripsRepository(
        ref.watch(apiClientProvider),
        kScreenshotMockTrips,
      ),
    ),
    profileRepositoryProvider.overrideWith(
      (ref) => _ScreenshotProfileRepository(
        ref.watch(apiClientProvider),
        kScreenshotProfile,
      ),
    ),
    profileControllerProvider.overrideWith(
      (ref) => _ScreenshotProfileController(
        ref.watch(profileRepositoryProvider),
      ),
    ),
    notificationsRepositoryProvider.overrideWith(
      (ref) => _ScreenshotNotificationsRepository(
        ref.watch(apiClientProvider),
      ),
    ),
    homeAddressControllerProvider.overrideWith(
      (ref) => _ScreenshotHomeAddressController(
        ref.watch(homeAddressStoreProvider),
        ref.watch(profileRepositoryProvider),
      ),
    ),
  ];
}

class _ScreenshotAuthSessionController extends AuthSessionController {
  _ScreenshotAuthSessionController(super.storage, super.api) {
    state = const AuthSessionState(isLoading: false, isAuthenticated: true);
  }

  @override
  Future<void> load() async {}
}

class _ScreenshotTripsRepository extends TripsRepository {
  _ScreenshotTripsRepository(super.apiClient, this._trips);

  final List<Trip> _trips;

  @override
  Future<Result<List<Trip>>> getMyTrips() async => Success(_trips);

  @override
  Future<Result<PackingListResult>> fetchPackingList(int reservationId) async =>
      Success(kScreenshotPackingList);

  @override
  Future<Result<TimelineResult>> fetchTimeline(int reservationId) async =>
      Success(kScreenshotTimeline);

  @override
  Future<Result<List<Map<String, dynamic>>>> getTodos(int reservationId) async =>
      Success(kScreenshotTodos);

  @override
  Future<Result<Map<String, dynamic>>> airportIndoorMap({
    required int reservationId,
    String? gate,
    String? highlight,
  }) async =>
      Failure('screenshot_mode');

  @override
  Future<Result<Map<String, dynamic>>> getDeparturePlan({
    required int reservationId,
    double? lat,
    double? lng,
    String mode = 'driving',
  }) async =>
      Success(kScreenshotDeparturePlan);

  @override
  Future<Result<Map<String, dynamic>>> locationCheck({
    required int reservationId,
    required double lat,
    required double lng,
  }) async =>
      Success({
        'at_airport': false,
        'distance_km': 9.0,
        'departure_plan': kScreenshotDeparturePlan,
      });

  @override
  Future<Result<Map<String, dynamic>>> airportDashboard({
    required int reservationId,
    required double lat,
    required double lng,
  }) async =>
      Success(kScreenshotAirportDashboard);

  @override
  Future<Result<List<Map<String, dynamic>>>> getMyTickets() async =>
      Success(kScreenshotTickets);
}

class _ScreenshotProfileController extends ProfileController {
  _ScreenshotProfileController(super.repository) {
    state = const AsyncValue.data(kScreenshotProfile);
  }

  @override
  Future<void> loadProfile() async {
    state = const AsyncValue.data(kScreenshotProfile);
  }
}

class _ScreenshotProfileRepository extends ProfileRepository {
  _ScreenshotProfileRepository(super.apiClient, this._profile);

  final ProfileState _profile;

  @override
  Future<Result<ProfileState>> getProfile() async => Success(_profile);

  @override
  Future<Result<ProfileState>> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async =>
      Success(
        _profile.copyWith(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
        ),
      );

  @override
  Future<Result<Map<String, dynamic>>> getPreferences() async =>
      Success(kScreenshotHomePreferences);

  @override
  Future<Result<Map<String, dynamic>>> updatePreferences({
    String? homeAddress,
    double? homeLat,
    double? homeLng,
  }) async =>
      Success(kScreenshotHomePreferences);
}

class _ScreenshotNotificationsRepository extends NotificationsRepository {
  _ScreenshotNotificationsRepository(super.apiClient);

  @override
  Future<Result<List<Map<String, dynamic>>>> getNotifications() async =>
      Success(kScreenshotNotifications);

  @override
  Future<Result<void>> markAllRead() async => const Success(null);
}

class _ScreenshotHomeAddressController extends HomeAddressController {
  _ScreenshotHomeAddressController(super.localStore, super.profileRepository) {
    state = const HomeAddress(
      address: 'طرابلس، ليبيا',
      lat: 32.8872,
      lng: 13.1913,
    );
  }

  @override
  Future<void> ensureLoaded() async {
    state = const HomeAddress(
      address: 'طرابلس، ليبيا',
      lat: 32.8872,
      lng: 13.1913,
    );
  }
}
