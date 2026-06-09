import 'package:shared_preferences/shared_preferences.dart';

import '../models/home_address.dart';

class HomeAddressStore {
  static const _addressKey = 'home_address_text';
  static const _latKey = 'home_address_lat';
  static const _lngKey = 'home_address_lng';
  static const _useManualKey = 'home_address_use_manual';

  Future<HomeAddress> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HomeAddress(
      address: prefs.getString(_addressKey),
      lat: prefs.getDouble(_latKey),
      lng: prefs.getDouble(_lngKey),
      useManualOrigin: prefs.getBool(_useManualKey) ?? false,
    );
  }

  Future<void> save(HomeAddress value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.address == null || value.address!.trim().isEmpty) {
      await prefs.remove(_addressKey);
    } else {
      await prefs.setString(_addressKey, value.address!.trim());
    }
    if (value.lat == null) {
      await prefs.remove(_latKey);
    } else {
      await prefs.setDouble(_latKey, value.lat!);
    }
    if (value.lng == null) {
      await prefs.remove(_lngKey);
    } else {
      await prefs.setDouble(_lngKey, value.lng!);
    }
    await prefs.setBool(_useManualKey, value.useManualOrigin);
  }
}
