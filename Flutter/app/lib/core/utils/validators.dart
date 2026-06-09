import '../../l10n/app_localizations.dart';

class Validators {
  Validators._();

  static String? required(
    String? value,
    AppLocalizations l10n, {
    required String fieldLabel,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired(fieldLabel);
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.emailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return l10n.emailInvalid;
    }

    return null;
  }

  static String? password(
    String? value,
    AppLocalizations l10n, {
    int minLength = 8,
  }) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }

    if (value.length < minLength) {
      return l10n.passwordMinLength(minLength);
    }

    return null;
  }

  static String? confirmPassword(
    String? value,
    String originalPassword,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequired;
    }

    if (value != originalPassword) {
      return l10n.passwordsDoNotMatch;
    }

    return null;
  }

  static String? phone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.phoneRequired;
    }

    final phoneRegex = RegExp(r'^\+?[0-9\s-]{10,}$');

    if (!phoneRegex.hasMatch(value)) {
      return l10n.phoneInvalid;
    }

    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
