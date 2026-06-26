import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/error_message_localizer.dart';
import '../../../l10n/app_localizations.dart';
import 'profile_guest_avatar.dart';
import 'profile_state.dart';
import '../../../core/theme/app_theme_extension.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileControllerProvider);

    return profile.when(
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              localizeUserFacingError(error, l10n),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.salmon),
            ),
          ),
        ),
      ),
      data: (profile) => Scaffold(
        backgroundColor: colors.background,
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(profileControllerProvider.notifier).loadProfile(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 130),
                sliver: SliverList.list(
                  children: [
                    _ProfileIdentity(
                      fullName: profile.fullName,
                      email: profile.email,
                      avatarPath: profile.avatarPath,
                    ),
                    const SizedBox(height: 39),
                    _SectionTitle(l10n.profilePersonalInfo),
                    const SizedBox(height: 19),
                    _InfoCard(
                      label: l10n.profileFullNameLabel,
                      value: profile.fullName,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      label: l10n.profileEmailLabel,
                      value: profile.email,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      label: l10n.profilePhoneLabel,
                      value: profile.phoneNumber.isEmpty
                          ? l10n.profileAddPhone
                          : profile.phoneNumber,
                      leadingIcon: Icons.phone_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarPath;

  const _ProfileIdentity({
    required this.fullName,
    required this.email,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        ProfileAvatarImage(avatarPath: avatarPath),
        const SizedBox(height: 18),
        Text(
          fullName,
          style: TextStyle(
            color: colors.title,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          style: TextStyle(
            color: colors.body,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        color: colors.title,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? leadingIcon;

  const _InfoCard({required this.label, required this.value, this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: colors.title, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
