import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import 'register_controller.dart';

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
        const SnackBar(
          content: Text(
            'Please accept the Terms of Service and Privacy Policy.',
          ),
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
        const SnackBar(content: Text('Account created successfully!')),
      );
      context.goNamed('login');
    }
  }

  void _goToLogin() {
    context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);

    return Scaffold(
      backgroundColor: _RegisterColors.midnight,
      body: SafeArea(
        child: Column(
          children: [
            _RegisterHeader(
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
                      const Text(
                        'Start your journey.',
                        style: TextStyle(
                          color: _RegisterColors.title,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.25,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Join our community of global curators.',
                        style: TextStyle(
                          color: _RegisterColors.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 34),
                      _RegisterTextField(
                        controller: _fullNameController,
                        label: 'FULL NAME',
                        hint: 'Julianne Smith',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Full name'),
                      ),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _emailController,
                        label: 'EMAIL ADDRESS',
                        hint: 'curator@musafir.travel',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _passwordController,
                        label: 'PASSWORD',
                        hint: '••••••••••••',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: Validators.password,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      _PasswordStrength(password: _passwordController.text),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _confirmPasswordController,
                        label: 'CONFIRM PASSWORD',
                        hint: '••••••••••••',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        obscureIcon: Icons.visibility_off_outlined,
                        textInputAction: TextInputAction.done,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        onSubmitted: (_) => _onCreateAccountPressed(),
                      ),
                      const SizedBox(height: 22),
                      _TermsAgreement(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                      ),
                      const SizedBox(height: 38),
                      if (registerState.hasError) ...[
                        Text(
                          registerState.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _RegisterColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _CreateAccountButton(
                        isLoading: registerState.isLoading,
                        onPressed: _onCreateAccountPressed,
                      ),
                      const SizedBox(height: 36),
                      _LoginPrompt(onLoginPressed: _goToLogin),
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
  final VoidCallback onBackPressed;

  const _RegisterHeader({required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: _RegisterColors.header,
        border: Border(
          bottom: BorderSide(color: _RegisterColors.divider, width: 1),
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
              icon: const Icon(
                Icons.arrow_back,
                color: _RegisterColors.title,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Create Account',
            style: TextStyle(
              color: _RegisterColors.title,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: _RegisterColors.label,
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
          cursorColor: _RegisterColors.blue,
          style: const TextStyle(
            color: _RegisterColors.title,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: _RegisterColors.hint,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _RegisterColors.icon,
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
                      color: _RegisterColors.muted,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: _RegisterColors.field,
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
              borderSide: const BorderSide(color: _RegisterColors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _RegisterColors.coral),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _RegisterColors.coral),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final String password;

  const _PasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    final score = _passwordScore(password);
    final strength = switch (score) {
      0 || 1 => 'Weak',
      2 => 'Moderate',
      _ => 'Strong',
    };
    final strengthColor = switch (score) {
      0 || 1 => _RegisterColors.strengthWeak,
      2 => _RegisterColors.strengthModerate,
      _ => _RegisterColors.strengthStrong,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: score / 4,
            backgroundColor: _RegisterColors.progressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.info_outline, size: 10, color: strengthColor),
            const SizedBox(width: 4),
            Text(
              'Password strength: $strength',
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
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsAgreement({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            side: const BorderSide(color: _RegisterColors.muted),
            activeColor: _RegisterColors.blue,
            checkColor: _RegisterColors.midnight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: _RegisterColors.title),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy\nPolicy.',
                  style: TextStyle(color: _RegisterColors.title),
                ),
              ],
            ),
            style: TextStyle(
              color: _RegisterColors.body,
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
  final bool isLoading;
  final VoidCallback onPressed;

  const _CreateAccountButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _RegisterColors.blue.withValues(alpha: 0.7),
          width: 1,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: _RegisterColors.blue.withValues(alpha: 0.22),
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
            backgroundColor: _RegisterColors.blue,
            disabledBackgroundColor: _RegisterColors.blue.withValues(
              alpha: 0.6,
            ),
            foregroundColor: _RegisterColors.midnight,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _RegisterColors.midnight,
                  ),
                )
              : const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const _LoginPrompt({required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: _RegisterColors.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: onLoginPressed,
          style: TextButton.styleFrom(
            foregroundColor: _RegisterColors.coral,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Login →',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: _RegisterColors.coral,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterColors {
  _RegisterColors._();

  static const Color midnight = Color(0xFF061326);
  static const Color header = Color(0xFF07172D);
  static const Color field = Color(0xFF101F36);
  static const Color divider = Color(0xFF18304A);
  static const Color title = Color(0xFFD9E5FF);
  static const Color body = Color(0xFFC3CEE0);
  static const Color label = Color(0xFFAFC0DB);
  static const Color muted = Color(0xFF74839E);
  static const Color hint = Color(0xFF5F6F89);
  static const Color icon = Color(0xFF97BBFF);
  static const Color blue = Color(0xFF4A91F8);
  static const Color coral = Color(0xFFFF8B6E);
  static const Color strengthWeak = Color(0xFFE9413A);
  static const Color strengthModerate = Color(0xFFFFC34A);
  static const Color strengthStrong = Color(0xFF38D67A);
  static const Color progressTrack = Color(0xFF36445A);
}
