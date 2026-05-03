import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              error.toString(),
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
                    ),
                    const SizedBox(height: 39),
                    const _SectionTitle('Personal Information'),
                    const SizedBox(height: 19),
                    _InfoCard(label: 'FULL NAME', value: profile.fullName),
                    const SizedBox(height: 14),
                    _InfoCard(label: 'EMAIL ADDRESS', value: profile.email),
                    const SizedBox(height: 14),
                    _InfoCard(
                      label: 'PHONE NUMBER',
                      value: profile.phoneNumber.isEmpty
                          ? 'Add phone number'
                          : profile.phoneNumber,
                      leadingIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 40),
                    const _SectionTitle('Travel Preferences'),
                    const SizedBox(height: 21),
                    _InfoCard(
                      label: 'HOME LOCATION',
                      value: profile.location,
                      leadingIcon: Icons.location_on_outlined,
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

  const _ProfileIdentity({required this.fullName, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 103,
              height: 103,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_ProfileColors.lavender, _ProfileColors.salmon],
                ),
              ),
              child: const _AvatarPortrait(),
            ),
            Positioned(
              right: -1,
              bottom: 7,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _ProfileColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: _ProfileColors.background,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
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

class _AvatarPortrait extends StatelessWidget {
  const _AvatarPortrait();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: _ProfileColors.card,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 14,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _ProfileColors.hair,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned(
              top: 27,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _ProfileColors.skin,
              ),
            ),
            Positioned(
              top: 50,
              child: Container(
                width: 68,
                height: 54,
                decoration: const BoxDecoration(
                  color: _ProfileColors.suit,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
            ),
            const Positioned(
              top: 56,
              child: Icon(Icons.person, color: _ProfileColors.title, size: 39),
            ),
          ],
        ),
      ),
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
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFACA6);
  static const Color lavender = Color(0xFFC8D4FF);
  static const Color skin = Color(0xFFF2C2A3);
  static const Color hair = Color(0xFFC47A48);
  static const Color suit = Color(0xFF111927);
}
