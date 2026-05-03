import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_repository_impl.dart';
import '../../../auth/presentation/auth_session_controller.dart';
import '../profile_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    return Scaffold(
      backgroundColor: _SettingsColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _SettingsAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 34, 14, 130),
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: _SettingsColors.title,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _UserSummaryCard(profile: profile),
                  const SizedBox(height: 25),
                  const _SettingsSectionTitle('NOTIFICATION SETTINGS'),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notification Setting',
                    subtitle: 'Stay updated on your flights',
                    onTap: () => context.goNamed('notificationSettings'),
                  ),
                  const SizedBox(height: 26),
                  const _SettingsSectionTitle('ACCOUNT'),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () => context.goNamed('changePassword'),
                  ),
                  const SizedBox(height: 22),
                  _LogoutButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      await ref
                          .read(authSessionControllerProvider.notifier)
                          .clear();
                      if (context.mounted) {
                        context.goNamed('login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goNamed('profile'),
            child: const SizedBox(
              width: 34,
              height: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back,
                  color: _SettingsColors.title,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'MOSAFER',
            style: TextStyle(
              color: _SettingsColors.title,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  final ProfileState? profile;

  const _UserSummaryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
      decoration: BoxDecoration(
        color: _SettingsColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _SettingsColors.avatarBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: _SettingsColors.title,
                  size: 34,
                ),
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _SettingsColors.salmon,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: _SettingsColors.background,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? 'Traveler',
                  style: const TextStyle(
                    color: _SettingsColors.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  profile?.email ?? 'Mosafer account',
                  style: const TextStyle(
                    color: _SettingsColors.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 35,
            child: ElevatedButton(
              onPressed: () => context.goNamed('editProfile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _SettingsColors.chip,
                foregroundColor: _SettingsColors.title,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Edit\nProfile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String text;

  const _SettingsSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: _SettingsColors.section,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _SettingsColors.card,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: _SettingsColors.iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _SettingsColors.title, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _SettingsColors.title,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: _SettingsColors.body,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: _SettingsColors.title,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _SettingsColors.logoutBackground,
          foregroundColor: _SettingsColors.salmon,
          side: const BorderSide(color: _SettingsColors.logoutBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: const Icon(Icons.logout, size: 17),
        label: const Text(
          'Logout',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SettingsColors {
  _SettingsColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color chip = Color(0xFF2A3A56);
  static const Color iconBackground = Color(0xFF1C2D48);
  static const Color avatarBackground = Color(0xFFE7F2FF);
  static const Color logoutBackground = Color(0xFF2A0D23);
  static const Color logoutBorder = Color(0xFF551A3A);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFF9FB0CE);
  static const Color section = Color(0xFF8FA2C2);
  static const Color salmon = Color(0xFFFFACA6);
}
