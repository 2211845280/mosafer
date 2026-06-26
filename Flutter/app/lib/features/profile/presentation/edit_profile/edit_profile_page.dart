import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/debug/screenshot_fixtures.dart';
import '../../../../core/debug/screenshot_mode.dart';
import '../../../../l10n/app_localizations.dart';
import '../profile_guest_avatar.dart';
import '../profile_state.dart';
import '../../../../core/theme/app_theme_extension.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  Uint8List? _pendingAvatarBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    if (kScreenshotMode) {
      _applyProfileFields(kScreenshotProfile);
    } else {
      Future.microtask(_syncControllersFromProfile);
    }
  }

  void _applyProfileFields(ProfileState profile) {
    _nameController.text = profile.fullName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phoneNumber;
  }

  void _syncControllersFromProfile() {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile == null || !mounted) return;
    _applyProfileFields(profile);
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      if (_pendingAvatarBytes != null) {
        final avatarUploaded = await ref
            .read(profileControllerProvider.notifier)
            .uploadAvatarBytes(_pendingAvatarBytes!);
        if (!avatarUploaded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.unableUploadProfileImage)),
          );
          return;
        }
      }

      final success = await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );
      if (success && mounted) {
        setState(() => _pendingAvatarBytes = null);
        context.goNamed('profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingAvatarBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.valueOrNull;
    if (profile != null && profile.fullName.isNotEmpty) {
      if (_nameController.text != profile.fullName) {
        _nameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber;
      }
    }
    final avatarPath = profile?.avatarPath;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _EditProfileAppBar(l10n: l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 28, 13, 24),
                children: [
                  _ProfileAvatar(
                    avatarPath: avatarPath,
                    localBytes: _pendingAvatarBytes,
                    onTap: _pickAvatar,
                  ),
                  const SizedBox(height: 32),
                  _ProfileInputField(
                    label: l10n.fullNameLabel,
                    icon: Icons.person_outline,
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _ProfileInputField(
                    label: l10n.emailAddressLabel,
                    icon: Icons.alternate_email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _ProfileInputField(
                    label: l10n.phoneNumberLabel,
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\d+\-().\s#*]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 37,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.saveChanges,
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
  final AppLocalizations l10n;

  const _EditProfileAppBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goNamed('settings'),
            child: SizedBox(
              width: 31,
              height: 34,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back,
                  color: colors.title,
                  size: 19,
                ),
              ),
            ),
          ),
          Text(
            l10n.editProfileTitle,
            style: TextStyle(
              color: colors.title,
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
  final String? avatarPath;
  final Uint8List? localBytes;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.avatarPath,
    required this.localBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ProfileAvatarImage(
                avatarPath: avatarPath,
                localBytes: localBytes,
                size: 92,
                showGradientRing: false,
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 5,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.background,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: colors.background,
                  size: 18,
                ),
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
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const _ProfileInputField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: 1,
          cursorColor: colors.primary,
          style: TextStyle(
            color: colors.title,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.card,
            prefixIcon: Icon(icon, color: colors.title, size: 18),
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
              borderSide: BorderSide(color: colors.primary),
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
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        color: colors.title,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}
