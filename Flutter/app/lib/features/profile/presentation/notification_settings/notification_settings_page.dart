import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'notification_settings_state.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsControllerProvider);
    final controller = ref.read(
      notificationSettingsControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: _NotificationSettingsColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _NotificationSettingsAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 38, 10, 18),
                children: [
                  const _IntroCard(),
                  const SizedBox(height: 32),
                  _PushNotificationsRow(
                    isEnabled: settings.enabled,
                    onChanged: controller.setEnabled,
                  ),
                  const SizedBox(height: 24),
                  const Divider(
                    color: _NotificationSettingsColors.divider,
                    height: 1,
                  ),
                  const SizedBox(height: 21),
                  _SettingsOptionCard(
                    icon: Icons.flight_takeoff,
                    title: 'Flight Status & Gates',
                    subtitle: 'Real-time tracking of your active journeys.',
                    value: settings.flightStatusEnabled,
                    onChanged: controller.setFlightStatusEnabled,
                  ),
                  const SizedBox(height: 12),
                  _SettingsOptionCard(
                    icon: Icons.confirmation_number,
                    title: 'Booking Confirmations',
                    subtitle: 'Instant alerts for tickets and hotel vouchers.',
                    value: settings.bookingConfirmationsEnabled,
                    onChanged: controller.setBookingConfirmationsEnabled,
                  ),
                  const SizedBox(height: 12),
                  _SettingsOptionCard(
                    icon: Icons.volume_up_outlined,
                    title: 'Notification Sound',
                    subtitle: 'Play a sound when new alerts arrive.',
                    value: settings.soundEnabled,
                    onChanged: settings.enabled
                        ? controller.setSoundEnabled
                        : null,
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'DEVICE ID: ${settings.deviceId} | LAST SYNC: ${settings.lastSync}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _NotificationSettingsColors.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
              child: _EnableNotificationsButton(
                isEnabled: settings.enabled,
                onPressed: controller.enableNotifications,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsAppBar extends StatelessWidget {
  const _NotificationSettingsAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goNamed('settings'),
            child: const SizedBox(
              width: 31,
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back,
                  color: _NotificationSettingsColors.title,
                  size: 20,
                ),
              ),
            ),
          ),
          const Text(
            'Notifications',
            style: TextStyle(
              color: _NotificationSettingsColors.title,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(23, 22, 23, 23),
      decoration: BoxDecoration(
        color: _NotificationSettingsColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BellIconBox(),
          SizedBox(height: 24),
          Text(
            'Never miss an update',
            style: TextStyle(
              color: _NotificationSettingsColors.title,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Get real-time updates on gate\nchanges, boarding times, and flight\ndelays directly on your device.',
            style: TextStyle(
              color: _NotificationSettingsColors.body,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _BellIconBox extends StatelessWidget {
  const _BellIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: _NotificationSettingsColors.blue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.notifications,
        color: _NotificationSettingsColors.title,
        size: 24,
      ),
    );
  }
}

class _PushNotificationsRow extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _PushNotificationsRow({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Push\nNotifications',
            style: TextStyle(
              color: _NotificationSettingsColors.title,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _NotificationSettingsColors.switchTrack,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _NotificationSettingsColors.outline),
          ),
          child: Text(
            isEnabled ? 'ENABLED' : 'PERMISSION\nREQUIRED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled
                  ? _NotificationSettingsColors.enabled
                  : _NotificationSettingsColors.salmon,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: isEnabled,
          onChanged: onChanged,
          activeThumbColor: _NotificationSettingsColors.title,
          activeTrackColor: _NotificationSettingsColors.blue,
          inactiveThumbColor: _NotificationSettingsColors.muted,
          inactiveTrackColor: _NotificationSettingsColors.switchTrack,
        ),
      ],
    );
  }
}

class _SettingsOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
      decoration: BoxDecoration(
        color: _NotificationSettingsColors.card,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: _NotificationSettingsColors.title, size: 20),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _NotificationSettingsColors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _NotificationSettingsColors.body,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _NotificationSettingsColors.title,
              activeTrackColor: _NotificationSettingsColors.blue,
              inactiveThumbColor: _NotificationSettingsColors.muted,
              inactiveTrackColor: _NotificationSettingsColors.switchTrack,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnableNotificationsButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _EnableNotificationsButton({
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? _NotificationSettingsColors.enabled
              : _NotificationSettingsColors.blue,
          foregroundColor: _NotificationSettingsColors.background,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          isEnabled ? 'Notifications Enabled' : 'Enable Notifications',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _NotificationSettingsColors {
  _NotificationSettingsColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFF9FB0CE);
  static const Color muted = Color(0xFF6F7D94);
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFA982);
  static const Color enabled = Color(0xFF69D8A3);
  static const Color divider = Color(0xFF12213A);
  static const Color outline = Color(0xFF4A3F45);
  static const Color switchTrack = Color(0xFF2A3549);
}
