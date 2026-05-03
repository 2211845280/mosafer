import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../profile_state.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _formError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final password = _newPasswordController.text;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(password)) score++;
    return score;
  }

  Future<void> _savePassword() async {
    setState(() => _formError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (success && mounted) {
      context.goNamed('settings');
    } else if (mounted) {
      final error = ref.read(profileControllerProvider).error;
      setState(
        () => _formError = error?.toString() ?? 'Unable to update password',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ChangePasswordColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ChangePasswordAppBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(19, 18, 19, 24),
                  children: [
                    _PasswordField(
                      label: 'CURRENT PASSWORD',
                      hint: 'Enter current password',
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      onToggleVisibility: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Current password',
                      ),
                    ),
                    const SizedBox(height: 25),
                    _PasswordField(
                      label: 'NEW PASSWORD',
                      hint: 'Enter new password',
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onChanged: (_) => setState(() {}),
                      onToggleVisibility: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 9),
                    _PasswordStrengthIndicator(strength: _passwordStrength),
                    const SizedBox(height: 25),
                    _PasswordField(
                      label: 'CONFIRM NEW PASSWORD',
                      hint: 'Repeat new password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggleVisibility: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _newPasswordController.text,
                      ),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _formError!,
                        style: const TextStyle(
                          color: _ChangePasswordColors.salmon,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const _SafetyTipCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 10, 19, 24),
              child: SizedBox(
                height: 37,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ChangePasswordColors.blue,
                    foregroundColor: _ChangePasswordColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    'SAVE PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordAppBar extends StatelessWidget {
  const _ChangePasswordAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 8, 19, 0),
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
                  color: _ChangePasswordColors.title,
                  size: 19,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Change Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ChangePasswordColors.title,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 31),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ChangePasswordColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          cursorColor: _ChangePasswordColors.blue,
          style: const TextStyle(
            color: _ChangePasswordColors.title,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _ChangePasswordColors.hint,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: _ChangePasswordColors.field,
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _ChangePasswordColors.muted,
                size: 19,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _ChangePasswordColors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final int strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final label = switch (strength) {
      0 || 1 => 'WEAK',
      2 || 3 => 'GOOD',
      _ => 'STRONG',
    };

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'PASSWORD STRENGTH',
              style: TextStyle(
                color: _ChangePasswordColors.muted,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: _ChangePasswordColors.title,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (index) {
            final isActive = index < strength;
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? _ChangePasswordColors.title
                      : _ChangePasswordColors.track,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SafetyTipCard extends StatelessWidget {
  const _SafetyTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        color: _ChangePasswordColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ChangePasswordColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _ChangePasswordColors.blue,
            child: Icon(
              Icons.shield_outlined,
              color: _ChangePasswordColors.background,
              size: 17,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Tip',
                  style: TextStyle(
                    color: _ChangePasswordColors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Use a combination of letters, numbers,\nand symbols to create a stronger\npassword.',
                  style: TextStyle(
                    color: _ChangePasswordColors.body,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordColors {
  _ChangePasswordColors._();

  static const Color background = Color(0xFF061326);
  static const Color field = Color(0xFF101F36);
  static const Color card = Color(0xFF101F36);
  static const Color border = Color(0xFF1F344F);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFFB8C6DC);
  static const Color muted = Color(0xFF7F90AA);
  static const Color hint = Color(0xFF43516A);
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFA982);
  static const Color track = Color(0xFF25344D);
}
