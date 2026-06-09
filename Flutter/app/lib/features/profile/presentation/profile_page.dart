import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/error_message_localizer.dart';
import '../../../l10n/app_localizations.dart';
import 'profile_guest_avatar.dart';
import 'profile_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileControllerProvider);

    return profile.when(
      loading: () => const Scaffold(
        backgroundColor: _ProfileColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: _ProfileColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              localizeUserFacingError(error, l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ProfileColors.salmon),
            ),
          ),
        ),
      ),
      data: (profile) => Scaffold(
        backgroundColor: _ProfileColors.background,
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
    return Column(
      children: [
        ProfileAvatarImage(avatarPath: avatarPath),
        const SizedBox(height: 18),
        Text(
          fullName,
          style: const TextStyle(
            color: _ProfileColors.title,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          style: const TextStyle(
            color: _ProfileColors.body,
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
    return Text(
      text,
      style: const TextStyle(
        color: _ProfileColors.title,
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
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
      decoration: BoxDecoration(
        color: _ProfileColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ProfileColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: _ProfileColors.title, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _ProfileColors.title,
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

class _ProfileColors {
  _ProfileColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFF9FB0CE);
  static const Color muted = Color(0xFF8A9AB3);
  static const Color salmon = Color(0xFFFFACA6);
}
