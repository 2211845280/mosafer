import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../profile_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
    if (success && mounted) {
      context.goNamed('profile');
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null) return;
    final success = await ref
        .read(profileControllerProvider.notifier)
        .uploadAvatar(image.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Profile image updated.' : 'Unable to upload image.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final isSaving = profileState.isLoading;

    return Scaffold(
      backgroundColor: _EditProfileColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _EditProfileAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 28, 13, 24),
                children: [
                  _ProfileAvatar(onTap: _pickAvatar),
                  const SizedBox(height: 16),
                  const Text(
                    'MUSAFIR VOYAGER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _EditProfileColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Traveler'
                        : _nameController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _EditProfileColors.title,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ProfileInputField(
                    label: 'FULL NAME',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _ProfileInputField(
                    label: 'EMAIL ADDRESS',
                    icon: Icons.alternate_email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _ProfileInputField(
                    label: 'PHONE NUMBER',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('TRAVEL PREFERENCES'),
                  const SizedBox(height: 12),
                  _ProfileInputField(
                    label: 'HOME LOCATION',
                    icon: Icons.location_on_outlined,
                    controller: _locationController,
                    suffixIcon: Icons.chevron_right,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 37,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EditProfileColors.blue,
                        foregroundColor: _EditProfileColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'SAVE CHANGES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                    ),
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

class _EditProfileAppBar extends StatelessWidget {
  const _EditProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
                  color: _EditProfileColors.title,
                  size: 19,
                ),
              ),
            ),
          ),
          const Text(
            'Edit Profile',
            style: TextStyle(
              color: _EditProfileColors.title,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: _EditProfileColors.avatarSuit,
                size: 60,
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 5,
            child: Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: _EditProfileColors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _EditProfileColors.background,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: _EditProfileColors.background,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData? suffixIcon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _ProfileInputField({
    required this.label,
    required this.icon,
    required this.controller,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          cursorColor: _EditProfileColors.blue,
          style: const TextStyle(
            color: _EditProfileColors.title,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _EditProfileColors.card,
            prefixIcon: Icon(icon, color: _EditProfileColors.title, size: 18),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: _EditProfileColors.title, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: _EditProfileColors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _EditProfileColors.title,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _EditProfileColors {
  _EditProfileColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF8FA2C2);
  static const Color blue = Color(0xFF1489FF);
  static const Color avatarSuit = Color(0xFF111927);
}
