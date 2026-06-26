import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../profile_state.dart';
import '../../../../core/theme/app_theme_extension.dart';

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
      final l10n = AppLocalizations.of(context)!;
      setState(
        () => _formError = error != null
            ? localizeUserFacingError(error, l10n)
            : l10n.errorUnableUpdatePassword,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
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
                      label: l10n.changePasswordCurrentLabel,
                      hint: l10n.changePasswordCurrentHint,
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      onToggleVisibility: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (value) => Validators.required(
                        value,
                        l10n,
                        fieldLabel: l10n.validationFieldCurrentPassword,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _PasswordField(
                      label: l10n.changePasswordNewLabel,
                      hint: l10n.changePasswordNewHint,
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onChanged: (_) => setState(() {}),
                      onToggleVisibility: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (v) => Validators.password(v, l10n),
                    ),
                    const SizedBox(height: 9),
                    _PasswordStrengthIndicator(
                      l10n: l10n,
                      strength: _passwordStrength,
                    ),
                    const SizedBox(height: 25),
                    _PasswordField(
                      label: l10n.changePasswordConfirmLabel,
                      hint: l10n.changePasswordRepeatHint,
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggleVisibility: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _newPasswordController.text,
                        l10n,
                      ),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _formError!,
                        style: TextStyle(
                          color: colors.salmon,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _SafetyTipCard(l10n: l10n),
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
                    backgroundColor: colors.primary,
                    foregroundColor: colors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    l10n.changePasswordSave,
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 8, 19, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goNamed('settings'),
            child: SizedBox(
              width: 31,
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back,
                  color: colors.title,
                  size: 19,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.changePasswordTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.title,
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
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.muted,
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
          cursorColor: colors.primary,
          style: TextStyle(
            color: colors.title,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.hint,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: colors.field,
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colors.muted,
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
              borderSide: BorderSide(color: colors.primary),
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
  final AppLocalizations l10n;
  final int strength;

  const _PasswordStrengthIndicator({
    required this.l10n,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (strength) {
      0 || 1 => l10n.passwordStrengthMeterWeak,
      2 || 3 => l10n.passwordStrengthMeterGood,
      _ => l10n.passwordStrengthMeterStrong,
    };

    return Column(
      children: [
        Row(
          children: [
            Text(
              l10n.passwordStrengthMeterTitle,
              style: TextStyle(
                color: colors.muted,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: colors.title,
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
                      ? colors.title
                      : colors.progressTrack,
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
  final AppLocalizations l10n;

  const _SafetyTipCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primary,
            child: Icon(
              Icons.shield_outlined,
              color: colors.background,
              size: 17,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.safetyTipTitle,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.safetyTipBody,
                  style: TextStyle(
                    color: colors.body,
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
