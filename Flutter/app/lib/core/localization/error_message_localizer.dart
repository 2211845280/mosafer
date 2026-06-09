import '../errors/app_exception.dart';
import '../../l10n/app_localizations.dart';

/// Maps known exceptions to short, user-facing messages in the current locale.
String localizeUserFacingError(Object error, AppLocalizations l10n) {
  if (error is NetworkException) {
    switch (error.code) {
      case 'TIMEOUT':
        return l10n.errorConnectionTimeout;
      case 'NO_CONNECTION':
        return l10n.errorNoInternet;
      default:
        break;
    }
  }
  if (error is UnauthorizedException) {
    return l10n.errorUnauthorized;
  }
  if (error is AppException) {
    final msg = error.message;
    if (msg.isNotEmpty &&
        !msg.toLowerCase().contains('dioexception') &&
        !msg.toLowerCase().contains('appexception')) {
      return msg;
    }
  }
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('connection refused') ||
      raw.contains('failed host lookup')) {
    return l10n.errorNoInternet;
  }
  return l10n.errorGeneric;
}
