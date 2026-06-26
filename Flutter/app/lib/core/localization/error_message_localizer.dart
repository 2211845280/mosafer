import '../errors/app_exception.dart';
import '../../l10n/app_localizations.dart';

String _normalizeApiMessage(String message) {
  return message.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String? _localizeConnectionIssue(String message, AppLocalizations l10n) {
  final lower = message.toLowerCase();
  if (lower.contains('connection timeout')) {
    return l10n.errorConnectionTimeout;
  }
  if (lower.contains('no internet connection') ||
      lower.contains('connection refused') ||
      lower.contains('failed host lookup') ||
      lower.contains('unable to connect')) {
    return l10n.errorNoInternet;
  }
  if (lower.contains('backend did not return auth tokens') ||
      lower.contains('service unavailable') ||
      lower.contains('is the api running')) {
    return l10n.errorServerUnavailable;
  }
  return null;
}

/// Maps known FastAPI `detail` strings to localized user-facing messages.
String? _localizeApiDetail(String message, AppLocalizations l10n) {
  final normalized = _normalizeApiMessage(message);
  if (normalized.isEmpty) return null;

  String? matchContains(List<String> needles, String localized) {
    for (final needle in needles) {
      if (normalized.contains(needle)) return localized;
    }
    return null;
  }

  return matchContains(
        ['seat already taken', 'seat already taken on this flight'],
        l10n.errorSeatAlreadyTaken,
      ) ??
      matchContains(
        ['seat no longer available'],
        l10n.errorSeatNoLongerAvailable,
      ) ??
      matchContains(
        ['seat is not part of this booking'],
        l10n.errorSeatNotInBooking,
      ) ??
      matchContains(
        ['duplicate seat numbers in the same booking'],
        l10n.errorDuplicateSeats,
      ) ??
      matchContains(
        ['invalid seat format'],
        l10n.errorInvalidSeatFormat,
      ) ??
      matchContains(
        ['checkout session expired'],
        l10n.errorCheckoutExpired,
      ) ??
      matchContains(
        ['passenger details already submitted'],
        l10n.errorPassengerDetailsSubmitted,
      ) ??
      matchContains(
        ['reservation not found'],
        l10n.errorReservationNotFound,
      ) ??
      matchContains(
        ['not your reservation'],
        l10n.errorNotYourReservation,
      ) ??
      matchContains(
        ['already cancelled'],
        l10n.errorAlreadyCancelled,
      ) ??
      matchContains(
        ['cannot cancel a past flight'],
        l10n.errorCannotCancelPastFlight,
      ) ??
      matchContains(
        ['duplicate passport numbers in the same booking'],
        l10n.errorDuplicatePassports,
      ) ??
      matchContains(
        [
          'invalid credentials',
          'incorrect email or password',
          'invalid email or password',
        ],
        l10n.errorInvalidCredentials,
      ) ??
      matchContains(
        ['please verify your email'],
        l10n.errorEmailNotVerified,
      ) ??
      matchContains(
        ['account is disabled'],
        l10n.errorAccountDisabled,
      ) ??
      matchContains(
        ['an account with this email already exists'],
        l10n.errorEmailAlreadyExists,
      ) ??
      matchContains(
        ['current password is incorrect'],
        l10n.errorCurrentPasswordIncorrect,
      ) ??
      matchContains(
        ['ticket not found'],
        l10n.scanTicketNotFound,
      ) ??
      matchContains(
        ['qr payload does not contain a ticket number'],
        l10n.scanTicketInvalid,
      );
}

String _localizeScanErrorCode(String message, AppLocalizations l10n) {
  if (!message.startsWith('scan:')) return message;
  switch (message.substring(5)) {
    case 'no_qr_in_image':
      return l10n.scanNoQrInImage;
    case 'ticket_not_found':
      return l10n.scanTicketNotFound;
    case 'invalid_ticket':
      return l10n.scanTicketInvalid;
    case 'expired_ticket':
      return l10n.scanTicketExpired;
    case 'ticket_already_assigned':
      return l10n.scanTicketAlreadyAssigned;
    case 'image_upload':
      return l10n.scanImageUploadError;
    default:
      return l10n.scanValidateTicketError;
  }
}

String _localizeMessage(String message, AppLocalizations l10n) {
  if (message.startsWith('scan:')) {
    return _localizeScanErrorCode(message, l10n);
  }

  final connection = _localizeConnectionIssue(message, l10n);
  if (connection != null) return connection;

  final localizedApi = _localizeApiDetail(message, l10n);
  if (localizedApi != null) return localizedApi;

  final lower = message.toLowerCase();
  if (message.isNotEmpty &&
      !lower.contains('dioexception') &&
      !lower.contains('appexception') &&
      !lower.startsWith('stateerror')) {
    return message;
  }

  return l10n.errorGeneric;
}

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
    final localized = _localizeApiDetail(error.message, l10n);
    if (localized != null) return localized;
    return l10n.errorInvalidCredentials;
  }
  if (error is AppException) {
    return _localizeMessage(error.message, l10n);
  }
  if (error is String) {
    return _localizeMessage(error, l10n);
  }
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('connection refused') ||
      raw.contains('failed host lookup')) {
    return l10n.errorNoInternet;
  }
  return l10n.errorGeneric;
}
