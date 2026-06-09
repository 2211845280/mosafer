import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/profile_repository.dart';
import '../models/home_address.dart';
import 'home_address_store.dart';

final homeAddressStoreProvider = Provider<HomeAddressStore>(
  (ref) => HomeAddressStore(),
);

final homeAddressControllerProvider =
    StateNotifierProvider<HomeAddressController, HomeAddress>(
      (ref) => HomeAddressController(
        ref.watch(homeAddressStoreProvider),
        ref.watch(profileRepositoryProvider),
      ),
    );

class HomeAddressController extends StateNotifier<HomeAddress> {
  HomeAddressController(this._localStore, this._profileRepository)
    : super(const HomeAddress()) {
    _initialLoad = _load();
  }

  final HomeAddressStore _localStore;
  final ProfileRepository _profileRepository;
  late final Future<void> _initialLoad;

  Future<void> ensureLoaded() => _initialLoad;

  Future<void> _load() async {
    final local = await _localStore.load();
    state = local;

    final remote = await _profileRepository.getPreferences();
    remote.when(
      success: (prefs) {
        final remoteAddress = HomeAddress.fromJson(prefs);
        if (remoteAddress.hasCoordinates || (remoteAddress.address?.isNotEmpty ?? false)) {
          state = state.copyWith(
            address: remoteAddress.address ?? state.address,
            lat: remoteAddress.lat ?? state.lat,
            lng: remoteAddress.lng ?? state.lng,
          );
          _localStore.save(state);
        }
      },
      failure: (_) {},
    );
  }

  Future<String?> setManualAddress({
    required String address,
    required double lat,
    required double lng,
    String? formattedAddress,
  }) async {
    final next = HomeAddress(
      address: formattedAddress ?? address.trim(),
      lat: lat,
      lng: lng,
      useManualOrigin: true,
    );
    state = next;
    await _localStore.save(next);

    final remote = await _profileRepository.updatePreferences(
      homeAddress: next.address,
      homeLat: lat,
      homeLng: lng,
    );
    return remote.when(
      success: (_) => null,
      failure: (error) => error,
    );
  }

  Future<void> setUseManualOrigin(bool value) async {
    state = state.copyWith(useManualOrigin: value);
    await _localStore.save(state);
  }

  Future<void> setUseGpsOrigin() async {
    state = state.copyWith(useManualOrigin: false);
    await _localStore.save(state);
  }
}
