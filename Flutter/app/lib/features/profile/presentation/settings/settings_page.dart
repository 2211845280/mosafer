import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_providers.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/auth_session_reset.dart';
import '../notification_settings/notification_settings_state.dart';
import '../profile_guest_avatar.dart';
import '../profile_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final notificationsEnabled = ref.watch(
      notificationSettingsControllerProvider.select((s) => s.enabled),
    );
    final isDarkMode = ref.watch(appThemeModeProvider) == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SettingsAppBar(l10n: l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 34, 14, 130),
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _UserSummaryCard(l10n: l10n, profile: profile),
                  const SizedBox(height: 25),
                  _SettingsSectionTitle(l10n.settingsNotificationsSection),
                  const SizedBox(height: 12),
                  _SettingsToggleTile(
                    icon: Icons.notifications_none_outlined,
                    title: l10n.settingsNotificationTileTitle,
                    subtitle: l10n.settingsNotificationTileSubtitle,
                    value: notificationsEnabled,
                    onChanged: ref
                        .read(notificationSettingsControllerProvider.notifier)
                        .setEnabled,
                  ),
                  const SizedBox(height: 26),
                  _SettingsSectionTitle(l10n.settingsDisplaySection),
                  const SizedBox(height: 12),
                  _SettingsToggleTile(
                    icon: isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: l10n.settingsThemeTileTitle,
                    subtitle: l10n.settingsThemeTileSubtitle,
                    value: isDarkMode,
                    onChanged: (enabled) => ref
                        .read(appThemeModeProvider.notifier)
                        .setDarkMode(enabled),
                  ),
                  const SizedBox(height: 26),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: l10n.settingsLanguage,
                    subtitle:
                        '${ref.watch(appLocaleProvider).languageCode == 'ar' ? l10n.languageArabic : l10n.languageEnglish} · ${l10n.settingsLanguageSubtitle}',
                    onTap: () => _showLanguagePicker(context, ref),
                  ),
                  const SizedBox(height: 26),
                  _SettingsSectionTitle(l10n.settingsAccountSection),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    title: l10n.settingsDeletedTrips,
                    subtitle: l10n.settingsDeletedTripsSubtitle,
                    onTap: () => context.goNamed('deletedTrips'),
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: l10n.settingsChangePassword,
                    onTap: () => context.goNamed('changePassword'),
                  ),
                  const SizedBox(height: 22),
                  _LogoutButton(
                    l10n: l10n,
                    onPressed: () async {
                      await logoutUser(ref);
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

Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final current = ref.read(appLocaleProvider);
  final colors = context.colors;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final dialogColors = ctx.colors;
      return AlertDialog(
        backgroundColor: dialogColors.card,
        title: Text(
          l10n.settingsChooseLanguageTitle,
          style: TextStyle(color: dialogColors.title),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n.languageEnglish,
                style: TextStyle(color: dialogColors.title),
              ),
              trailing: current.languageCode == 'en'
                  ? Icon(Icons.check, color: dialogColors.salmon)
                  : null,
              onTap: () async {
                await ref
                    .read(appLocaleProvider.notifier)
                    .setLocale(const Locale('en'));
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text(
                l10n.languageArabic,
                style: TextStyle(color: dialogColors.title),
              ),
              trailing: current.languageCode == 'ar'
                  ? Icon(Icons.check, color: dialogColors.salmon)
                  : null,
              onTap: () async {
                await ref
                    .read(appLocaleProvider.notifier)
                    .setLocale(const Locale('ar'));
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

class _SettingsAppBar extends StatelessWidget {
  final AppLocalizations l10n;

  const _SettingsAppBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goNamed('profile'),
            child: SizedBox(
              width: 34,
              height: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back,
                  color: colors.title,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            l10n.brandMosafer,
            style: TextStyle(
              color: colors.title,
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
  final AppLocalizations l10n;
  final ProfileState? profile;

  const _UserSummaryCard({required this.l10n, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colors.avatarBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ProfileAvatarImage(
              avatarPath: profile?.avatarPath,
              size: 50,
              showGradientRing: false,
              borderRadius: 12,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? l10n.travelerDefault,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? l10n.mosaferAccountDefault,
                  style: TextStyle(
                    color: colors.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.goNamed('editProfile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 35),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.settingsEditProfileTwoLines,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.2,
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
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        text,
        style: TextStyle(
          color: colors.section,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: colors.iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.title, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: colors.body,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
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
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: colors.iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colors.title, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.body,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.title,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onPressed;

  const _LogoutButton({required this.l10n, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.logoutBackground,
          foregroundColor: colors.salmon,
          side: BorderSide(color: colors.logoutBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: const Icon(Icons.logout, size: 17),
        label: Text(
          l10n.settingsLogout,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
