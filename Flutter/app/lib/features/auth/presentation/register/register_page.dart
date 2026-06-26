import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../../../l10n/app_localizations.dart';
import 'register_controller.dart';
import '../../../../core/theme/app_theme_extension.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccountPressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.registerTermsNotAccepted),
        ),
      );
      return;
    }

    final success = await ref
        .read(registerControllerProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.registerAccountCreated),
        ),
      );
      context.goNamed('login');
    }
  }

  void _goToLogin() {
    context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registerState = ref.watch(registerControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _RegisterHeader(
              l10n: l10n,
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed('login');
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.registerStartJourneyTitle,
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.25,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.registerJoinCommunity,
                        style: TextStyle(
                          color: colors.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 34),
                      _RegisterTextField(
                        controller: _fullNameController,
                        label: l10n.registerFullNameLabel,
                        hint: l10n.registerFullNameHint,
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.required(
                          value,
                          l10n,
                          fieldLabel: l10n.validationFieldFullName,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _emailController,
                        label: l10n.emailAddressLabel,
                        hint: l10n.registerEmailHint,
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.email(v, l10n),
                      ),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _passwordController,
                        label: l10n.registerPasswordLabel,
                        hint: '••••••••••••',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.password(v, l10n),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      _PasswordStrength(
                        l10n: l10n,
                        password: _passwordController.text,
                      ),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _confirmPasswordController,
                        label: l10n.registerConfirmPasswordLabel,
                        hint: '••••••••••••',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        obscureIcon: Icons.visibility_off_outlined,
                        textInputAction: TextInputAction.done,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                          l10n,
                        ),
                        onSubmitted: (_) => _onCreateAccountPressed(),
                      ),
                      const SizedBox(height: 22),
                      _TermsAgreement(
                        l10n: l10n,
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                      ),
                      const SizedBox(height: 38),
                      if (registerState.hasError) ...[
                        Text(
                          localizeUserFacingError(registerState.error!, l10n),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _CreateAccountButton(
                        l10n: l10n,
                        isLoading: registerState.isLoading,
                        onPressed: _onCreateAccountPressed,
                      ),
                      const SizedBox(height: 36),
                      _LoginPrompt(l10n: l10n, onLoginPressed: _goToLogin),
                      const SizedBox(height: 18),
                    ],
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

class _RegisterHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onBackPressed;

  const _RegisterHeader({required this.l10n, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.header,
        border: Border(
          bottom: BorderSide(color: colors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 22,
              onPressed: onBackPressed,
              icon: Icon(
                Icons.arrow_back,
                color: colors.title,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.registerCreateAccount,
            style: TextStyle(
              color: colors.title,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final IconData? obscureIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _RegisterTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_RegisterTextField> createState() => _RegisterTextFieldState();
}

class _RegisterTextFieldState extends State<_RegisterTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            widget.label,
            style: TextStyle(
              color: colors.label,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          cursorColor: colors.primary,
          style: TextStyle(
            color: colors.title,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colors.hint,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: colors.icon,
              size: 19,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () {
                      setState(() => _isObscured = !_isObscured);
                    },
                    icon: Icon(
                      _isObscured
                          ? (widget.obscureIcon ?? Icons.visibility_outlined)
                          : Icons.visibility_off_outlined,
                      color: colors.muted,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors.field,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: colors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: colors.coral),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: colors.coral),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final AppLocalizations l10n;
  final String password;

  const _PasswordStrength({required this.l10n, required this.password});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final score = _passwordScore(password);
    final strength = switch (score) {
      0 || 1 => l10n.passwordStrengthWeak,
      2 => l10n.passwordStrengthModerate,
      _ => l10n.passwordStrengthStrong,
    };
    final strengthColor = switch (score) {
      0 || 1 => colors.strengthWeak,
      2 => colors.strengthModerate,
      _ => colors.strengthStrong,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: score / 4,
            backgroundColor: colors.progressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.info_outline, size: 10, color: strengthColor),
            const SizedBox(width: 4),
            Text(
              l10n.passwordStrengthLabel(strength),
              style: TextStyle(
                color: strengthColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _passwordScore(String password) {
    if (password.isEmpty) {
      return 1;
    }

    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score.clamp(1, 4);
  }
}

class _TermsAgreement extends StatelessWidget {
  final AppLocalizations l10n;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsAgreement({
    required this.l10n,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            side: BorderSide(color: colors.muted),
            activeColor: colors.primary,
            checkColor: colors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: l10n.termsAgreePrefix,
              children: [
                TextSpan(
                  text: l10n.termsOfService,
                  style: TextStyle(color: colors.title),
                ),
                TextSpan(text: l10n.termsAnd),
                TextSpan(
                  text: l10n.termsPrivacyPolicy,
                  style: TextStyle(color: colors.title),
                ),
              ],
            ),
            style: TextStyle(
              color: colors.body,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CreateAccountButton({
    required this.l10n,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.7),
          width: 1,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 46,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            disabledBackgroundColor: colors.primary.withValues(
              alpha: 0.6,
            ),
            foregroundColor: colors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.background,
                  ),
                )
              : Text(
                  l10n.registerCreateAccount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onLoginPressed;

  const _LoginPrompt({required this.l10n, required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.registerAlreadyHaveAccount,
          style: TextStyle(
            color: colors.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: onLoginPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.coral,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.registerLoginArrow,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: colors.coral,
            ),
          ),
        ),
      ],
    );
  }
}
