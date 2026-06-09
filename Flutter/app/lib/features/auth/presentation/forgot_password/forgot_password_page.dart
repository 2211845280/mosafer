import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../data/auth_repository_impl.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  String? _devResetLink;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
      _devResetLink = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .requestPasswordReset(email: _emailController.text.trim());

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    result.when(
      success: (resetLink) {
        setState(() {
          _isLoading = false;
          _successMessage = l10n.forgotPasswordSuccess;
          _devResetLink = resetLink;
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
        title: Text(l10n.forgotPasswordTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  l10n.forgotPasswordSubtitle,
                  style: const TextStyle(
                    color: _AuthColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  validator: (v) => Validators.email(v, l10n),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onSubmit(),
                  cursorColor: _AuthColors.blue,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    label: l10n.loginEmailLabel,
                    hint: l10n.loginEmailHint,
                    icon: Icons.mail_outline,
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
                if (_successMessage != null) ...[
                  Text(
                    _successMessage!,
                    style: const TextStyle(
                      color: _AuthColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_devResetLink != null) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      _devResetLink!,
                      style: const TextStyle(
                        color: _AuthColors.ice,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                            l10n.forgotPasswordSubmit,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.goNamed('login'),
                  child: Text(
                    l10n.forgotPasswordBackToLogin,
                    style: const TextStyle(color: _AuthColors.coral),
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
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _AuthColors.muted, fontSize: 10),
      hintText: hint,
      hintStyle: const TextStyle(color: _AuthColors.hint),
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
  static const Color ice = Color(0xFFE4ECFF);
  static const Color muted = Color(0xFFB4C0D6);
  static const Color hint = Color(0xFF586983);
  static const Color coral = Color(0xFFFF8B6E);
}
