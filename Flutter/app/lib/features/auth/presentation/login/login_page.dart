import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import 'login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _staySignedIn = true;

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
    final loginState = ref.watch(loginControllerProvider);

    return Scaffold(
      backgroundColor: _LoginColors.midnight,
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
                          const _LoginBrand(),
                          SizedBox(height: constraints.maxHeight * 0.06),
                          _DesignedTextField(
                            controller: _emailController,
                            label: 'EMAIL ADDRESS',
                            hint: 'voyager@ethereal.com',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 18),
                          _DesignedTextField(
                            controller: _passwordController,
                            label: 'SECURITY KEY',
                            hint: '••••••••••',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: Validators.password,
                            trailingLabel: 'FORGOT?',
                            onSubmitted: (_) => _onLoginPressed(),
                          ),
                          const SizedBox(height: 14),
                          _StaySignedInRow(
                            value: _staySignedIn,
                            onChanged: (value) {
                              setState(() => _staySignedIn = value);
                            },
                          ),
                          const SizedBox(height: 18),
                          if (loginState.hasError) ...[
                            Text(
                              loginState.error.toString(),
                              style: const TextStyle(
                                color: _LoginColors.coral,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _LoginButton(
                            isLoading: loginState.isLoading,
                            onPressed: _onLoginPressed,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.06),
                          const _RegisterPrompt(),
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
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _LoginColors.field.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Icon(
            Icons.travel_explore,
            color: _LoginColors.blue,
            size: 29,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'MOSAFER',
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
        const Text(
          'YOUR DIGITAL CURATOR FOR THE UNKNOWN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _LoginColors.ice,
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
                  style: const TextStyle(
                    color: _LoginColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.05,
                  ),
                ),
              ),
              if (widget.trailingLabel != null)
                Text(
                  widget.trailingLabel!,
                  style: const TextStyle(
                    color: _LoginColors.coral,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
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
          cursorColor: _LoginColors.blue,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: _LoginColors.hint,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(widget.icon, color: _LoginColors.blue, size: 19),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () {
                      setState(() => _isObscured = !_isObscured);
                    },
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _LoginColors.muted,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: _LoginColors.field,
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
              borderSide: const BorderSide(color: _LoginColors.blue, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _LoginColors.coral, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _LoginColors.coral, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaySignedInRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StaySignedInRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Always remember me',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.78,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _LoginColors.field,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _LoginColors.field,
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _LoginColors.blue.withValues(alpha: 0.75),
          width: 1,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: _LoginColors.blue.withValues(alpha: 0.26),
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
            backgroundColor: _LoginColors.blue,
            disabledBackgroundColor: _LoginColors.blue.withValues(alpha: 0.6),
            foregroundColor: _LoginColors.midnight,
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
                    color: _LoginColors.midnight,
                  ),
                )
              : const Text(
                  'Login to Mosafer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New to the voyage? ',
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
            foregroundColor: _LoginColors.coral,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Register Now',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: _LoginColors.coral,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
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

class _LoginColors {
  _LoginColors._();

  static const Color midnight = Color(0xFF061326);
  static const Color field = Color(0xFF0C1B31);
  static const Color blue = Color(0xFF4A91F8);
  static const Color ice = Color(0xFFE4ECFF);
  static const Color muted = Color(0xFFB4C0D6);
  static const Color hint = Color(0xFF586983);
  static const Color coral = Color(0xFFFF8B6E);
}
