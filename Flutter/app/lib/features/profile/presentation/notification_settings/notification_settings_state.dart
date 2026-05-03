import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsState {
  final bool enabled;
  final bool soundEnabled;
  final bool flightStatusEnabled;
  final bool bookingConfirmationsEnabled;
  final String deviceId;
  final String lastSync;

  const NotificationSettingsState({
    required this.enabled,
    required this.soundEnabled,
    required this.flightStatusEnabled,
    required this.bookingConfirmationsEnabled,
    required this.deviceId,
    required this.lastSync,
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? flightStatusEnabled,
    bool? bookingConfirmationsEnabled,
    String? deviceId,
    String? lastSync,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      flightStatusEnabled: flightStatusEnabled ?? this.flightStatusEnabled,
      bookingConfirmationsEnabled:
          bookingConfirmationsEnabled ?? this.bookingConfirmationsEnabled,
      deviceId: deviceId ?? this.deviceId,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class NotificationSettingsController
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsController()
    : super(
        const NotificationSettingsState(
          enabled: false,
          soundEnabled: false,
          flightStatusEnabled: true,
          bookingConfirmationsEnabled: true,
          deviceId: 'MSF-992-X',
          lastSync: '2 MINS AGO',
        ),
      );

  void enableNotifications() {
    state = state.copyWith(enabled: true, soundEnabled: true);
  }

  void setEnabled(bool value) {
    state = state.copyWith(
      enabled: value,
      soundEnabled: value ? state.soundEnabled : false,
    );
  }

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
  }

  void setFlightStatusEnabled(bool value) {
    state = state.copyWith(flightStatusEnabled: value);
  }

  void setBookingConfirmationsEnabled(bool value) {
    state = state.copyWith(bookingConfirmationsEnabled: value);
  }
}

final notificationSettingsControllerProvider =
    StateNotifierProvider<
      NotificationSettingsController,
      NotificationSettingsState
    >((ref) => NotificationSettingsController());
