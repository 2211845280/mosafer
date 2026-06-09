import 'package:shared_preferences/shared_preferences.dart';

/// Demo check-in steps for Issue 3.
enum AirportArrivalStep {
  none,
  arrived,
  checkInStarted,
  boardingPassReady,
  goToGate;

  static AirportArrivalStep fromStored(int value) {
    if (value <= 0) {
      return AirportArrivalStep.none;
    }
    // Legacy: old goToGate was index 5 before proceedToSecurity was removed.
    if (value >= 5) {
      return AirportArrivalStep.goToGate;
    }
    if (value >= AirportArrivalStep.values.length) {
      return AirportArrivalStep.goToGate;
    }
    return AirportArrivalStep.values[value];
  }

  AirportArrivalStep? get nextStep {
    final nextIndex = index + 1;
    if (nextIndex >= AirportArrivalStep.values.length) {
      return null;
    }
    return AirportArrivalStep.values[nextIndex];
  }

  bool get hasStarted => index >= AirportArrivalStep.arrived.index;
  bool get isComplete => this == AirportArrivalStep.goToGate;
}

class AirportArrivalStore {
  static String _key(int reservationId) =>
      'airport_arrival_state_$reservationId';

  Future<AirportArrivalStep> loadStep(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_key(reservationId)) ?? 0;
    return AirportArrivalStep.fromStored(stored);
  }

  Future<void> saveStep(int reservationId, AirportArrivalStep step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(reservationId), step.index);
  }

  Future<void> reset(int reservationId) async {
    await saveStep(reservationId, AirportArrivalStep.none);
  }
}
