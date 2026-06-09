import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/home_address_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../profile_guest_avatar.dart';
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
  late final TextEditingController _homeAddressController;
  Uint8List? _pendingAvatarBytes;
  bool _isSaving = false;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _homeAddressController = TextEditingController(
      text: ref.read(homeAddressControllerProvider).address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveHomeAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final address = _homeAddressController.text.trim();
    if (address.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeAddressTooShort)),
      );
      return;
    }

    setState(() => _isSavingAddress = true);
    try {
      final geocoded = await ref.read(geocodingServiceProvider).geocode(address);
      final syncError = await ref
          .read(homeAddressControllerProvider.notifier)
          .setManualAddress(
            address: address,
            lat: geocoded.lat,
            lng: geocoded.lng,
            formattedAddress: geocoded.formattedAddress,
          );
      if (!mounted) return;
      if (syncError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(syncError)),
        );
        return;
      }
      _homeAddressController.text = geocoded.formattedAddress;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeAddressSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeAddressGeocodeFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAddress = false);
      }
    }
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
    final profileState = ref.watch(profileControllerProvider);
    final avatarPath = profileState.valueOrNull?.avatarPath;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _EditProfileColors.background,
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
                  const SizedBox(height: 20),
                  _ProfileInputField(
                    label: l10n.homeLocationLabel,
                    icon: Icons.home_outlined,
                    controller: _homeAddressController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSavingAddress ? null : _saveHomeAddress,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _EditProfileColors.title,
                        side: BorderSide(
                          color: _EditProfileColors.title.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: _isSavingAddress
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.homeAddressSave,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 37,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EditProfileColors.blue,
                        foregroundColor: _EditProfileColors.background,
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
                              style: const TextStyle(
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
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back,
                  color: _EditProfileColors.title,
                  size: 19,
                ),
              ),
            ),
          ),
          Text(
            l10n.editProfileTitle,
            style: const TextStyle(
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
  final int? maxLines;

  const _ProfileInputField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
    this.maxLines,
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
          inputFormatters: inputFormatters,
          maxLines: maxLines ?? 1,
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
  static const Color blue = Color(0xFF1489FF);
}
