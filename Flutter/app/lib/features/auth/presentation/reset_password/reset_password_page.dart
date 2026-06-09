import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../data/auth_repository_impl.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordPage({super.key, this.token});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _completed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context)!.resetPasswordInvalidLink;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(authRepositoryProvider).resetPassword(
          token: token,
          newPassword: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    result.when(
      success: (_) {
        setState(() {
          _isLoading = false;
          _completed = true;
        });
      },
      failure: (error) {
        setState(() {
          _isLoading = false;
          _error = localizeUserFacingError(error, l10n);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _AuthColors.midnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(l10n.resetPasswordTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _completed
              ? Column(
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      l10n.resetPasswordSuccess,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _AuthColors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.goNamed('login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AuthColors.blue,
                        foregroundColor: _AuthColors.midnight,
                      ),
                      child: Text(l10n.forgotPasswordBackToLogin),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        l10n.resetPasswordSubtitle,
                        style: const TextStyle(
                          color: _AuthColors.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (v) => Validators.password(v, l10n),
                        textInputAction: TextInputAction.next,
                        cursorColor: _AuthColors.blue,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          label: l10n.registerPasswordLabel,
                          icon: Icons.lock_outline,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                          l10n,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onSubmit(),
                        cursorColor: _AuthColors.blue,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          label: l10n.registerConfirmPasswordLabel,
                          icon: Icons.lock_outline,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: _AuthColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _AuthColors.blue,
                            foregroundColor: _AuthColors.midnight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  l10n.resetPasswordSubmit,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _AuthColors.muted, fontSize: 10),
      prefixIcon: Icon(icon, color: _AuthColors.blue, size: 19),
      filled: true,
      fillColor: _AuthColors.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _AuthColors {
  static const Color midnight = Color(0xFF061326);
  static const Color field = Color(0xFF0C1B31);
  static const Color blue = Color(0xFF4A91F8);
  static const Color muted = Color(0xFFB4C0D6);
  static const Color coral = Color(0xFFFF8B6E);
}
