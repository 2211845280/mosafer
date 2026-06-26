import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../auth_session_reset.dart';
import 'login_controller.dart';
import '../../../../core/theme/app_theme_extension.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _switchSessionPrepared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _prepareSwitchAccount(),
    );
  }

  Future<void> _prepareSwitchAccount() async {
    if (_switchSessionPrepared || !mounted) {
      return;
    }
    final switchAccount =
        GoRouterState.of(context).uri.queryParameters['switch'] == '1';
    if (!switchAccount) {
      return;
    }
    _switchSessionPrepared = true;
    await resetUserSession(ref);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(loginControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (success && mounted) {
      context.goNamed('myTrips');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loginState = ref.watch(loginControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.13),
                          _LoginBrand(l10n: l10n),
                          SizedBox(height: constraints.maxHeight * 0.06),
                          _DesignedTextField(
                            controller: _emailController,
                            label: l10n.loginEmailLabel,
                            hint: l10n.loginEmailHint,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => Validators.email(v, l10n),
                          ),
                          const SizedBox(height: 18),
                          _DesignedTextField(
                            controller: _passwordController,
                            label: l10n.loginPasswordLabel,
                            hint: '••••••••••',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => Validators.password(v, l10n),
                            trailingLabel: l10n.loginForgot,
                            onTrailingTap: () =>
                                context.pushNamed('forgotPassword'),
                            onSubmitted: (_) => _onLoginPressed(),
                          ),
                          const SizedBox(height: 18),
                          if (loginState.hasError) ...[
                            Text(
                              localizeUserFacingError(loginState.error!, l10n),
                              style: TextStyle(
                                color: colors.coral,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _LoginButton(
                            l10n: l10n,
                            isLoading: loginState.isLoading,
                            onPressed: _onLoginPressed,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.06),
                          _RegisterPrompt(l10n: l10n),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBrand extends StatelessWidget {
  final AppLocalizations l10n;

  const _LoginBrand({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/brand/mosafer_logo.png',
            height: 78,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.brandMosafer,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.loginTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.ice,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.35,
          ),
        ),
      ],
    );
  }
}

class _DesignedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _DesignedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.trailingLabel,
    this.onTrailingTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_DesignedTextField> createState() => _DesignedTextFieldState();
}

class _DesignedTextFieldState extends State<_DesignedTextField> {
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
          padding: const EdgeInsets.only(left: 3, right: 4, bottom: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.05,
                  ),
                ),
              ),
              if (widget.trailingLabel != null)
                GestureDetector(
                  onTap: widget.onTrailingTap,
                  child: Text(
                    widget.trailingLabel!,
                    style: TextStyle(
                      color: colors.coral,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          cursorColor: colors.primary,
          style: TextStyle(
            color: Colors.white,
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
            prefixIcon: Icon(widget.icon, color: colors.primary, size: 19),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () {
                      setState(() => _isObscured = !_isObscured);
                    },
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
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
              vertical: 15,
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
              borderSide: BorderSide(color: colors.primary, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: colors.coral, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: colors.coral, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({
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
          color: colors.primary.withValues(alpha: 0.75),
          width: 1,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.26),
            blurRadius: 18,
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
            disabledBackgroundColor: colors.primary.withValues(alpha: 0.6),
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
                  l10n.loginButton,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  final AppLocalizations l10n;

  const _RegisterPrompt({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.loginNewToVoyage,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            context.goNamed('register');
          },
          style: TextButton.styleFrom(
            foregroundColor: colors.coral,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.loginRegisterNow,
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

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08243D),
            Color(0xFF19304A),
            Color(0xFF08213A),
            Color(0xFF031021),
          ],
          stops: [0, 0.36, 0.72, 1],
        ),
      ),
      child: CustomPaint(
        painter: _MountainPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sunsetPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x772E1627), Color(0x998B5337), Color(0x77351E2E)],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.62,
              size.width,
              size.height * 0.09,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.09),
      sunsetPaint,
    );

    final farMountains = Path()
      ..moveTo(0, size.height * 0.67)
      ..lineTo(size.width * 0.14, size.height * 0.65)
      ..lineTo(size.width * 0.28, size.height * 0.66)
      ..lineTo(size.width * 0.43, size.height * 0.64)
      ..lineTo(size.width * 0.58, size.height * 0.66)
      ..lineTo(size.width * 0.76, size.height * 0.63)
      ..lineTo(size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(farMountains, Paint()..color = const Color(0xBB04172B));

    final nearMountains = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.86,
        size.width * 0.3,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.81,
        size.width * 0.64,
        size.height * 0.83,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.86,
        size.width,
        size.height * 0.84,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(nearMountains, Paint()..color = const Color(0xE9020C19));

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.95,
        colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.65),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
