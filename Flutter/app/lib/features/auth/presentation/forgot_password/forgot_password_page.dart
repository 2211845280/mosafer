import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../data/auth_repository_impl.dart';
import '../../../../core/theme/app_theme_extension.dart';

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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
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
                  style: TextStyle(
                    color: colors.muted,
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
                  cursorColor: colors.primary,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    context,
                    label: l10n.loginEmailLabel,
                    hint: l10n.loginEmailHint,
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 18),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: colors.coral,
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
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_devResetLink != null) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      _devResetLink!,
                      style: TextStyle(
                        color: colors.ice,
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
                      backgroundColor: colors.primary,
                      foregroundColor: colors.background,
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
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.goNamed('login'),
                  child: Text(
                    l10n.forgotPasswordBackToLogin,
                    style: TextStyle(color: colors.coral),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final colors = context.colors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.muted, fontSize: 10),
      hintText: hint,
      hintStyle: TextStyle(color: colors.hint),
      prefixIcon: Icon(icon, color: colors.primary, size: 19),
      filled: true,
      fillColor: colors.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
    );
  }
}
