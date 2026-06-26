import '../../features/notifications/presentation/notifications_controller.dart';
import '../../l10n/app_localizations.dart';

final _paymentAmountPattern = RegExp(
  r'([\d.,]+)\s*([A-Za-z]{3})',
);

final _flightCodePattern = RegExp(r'([A-Z]{2}\d+)');

(String title, String body) localizeNotification(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final type = notification.type.toLowerCase();
  final title = notification.title.trim();
  final body = notification.body.trim();

  if (type.contains('payment_success') || _isPaymentSuccessful(title)) {
    final parsed = _parsePaymentAmount(body);
    if (parsed != null) {
      return (
        l10n.notificationPaymentSuccessful,
        l10n.notificationPaymentSuccessfulBody(parsed.$1, parsed.$2),
      );
    }
    return (l10n.notificationPaymentSuccessful, body);
  }

  if (type.contains('payment_failed') || _isPaymentFailed(title)) {
    return (
      l10n.notificationPaymentFailed,
      l10n.notificationPaymentFailedBody,
    );
  }

  if (type.contains('payment_refunded') || _isPaymentRefunded(title)) {
    final parsed = _parsePaymentAmount(body);
    if (parsed != null) {
      return (
        l10n.notificationPaymentRefunded,
        l10n.notificationPaymentRefundedBody(parsed.$1, parsed.$2),
      );
    }
    return (l10n.notificationPaymentRefunded, body);
  }

  if (_isFullRefund(title)) {
    final parsed = _parsePaymentAmount(body);
    if (parsed != null) {
      return (
        l10n.notificationFullRefund,
        l10n.notificationFullRefundBody(parsed.$1, parsed.$2),
      );
    }
    return (l10n.notificationFullRefund, body);
  }

  if (_isPartialRefund(title)) {
    final parsed = _parsePaymentAmount(body);
    if (parsed != null) {
      return (
        l10n.notificationPartialRefund,
        l10n.notificationPartialRefundBody(parsed.$1, parsed.$2),
      );
    }
    return (l10n.notificationPartialRefund, body);
  }

  if (_isBookingCanceled(title)) {
    return (
      l10n.notificationBookingCanceled,
      l10n.notificationBookingCanceledBody,
    );
  }

  final tripTodo = _localizeTripTodoReminder(type, body, l10n);
  if (tripTodo != null) {
    return tripTodo;
  }

  final departureSchedule = _localizeDepartureSchedule(type, body, l10n);
  if (departureSchedule != null) {
    return departureSchedule;
  }

  final departure = _localizeDepartureAlert(type, title, body, l10n);
  if (departure != null) {
    return departure;
  }

  return (title, body);
}

(String title, String body)? _localizeTripTodoReminder(
  String type,
  String body,
  AppLocalizations l10n,
) {
  if (!type.startsWith('trip_todo_')) return null;
  final flight = _parseFlightCode(body) ?? '';
  final isEmpty =
      body.contains('fill') ||
      body.contains('تعبئة') ||
      body.toLowerCase().contains('fill in');
  if (isEmpty) {
    return (
      l10n.notificationTripTodoTitle,
      flight.isEmpty
          ? body
          : l10n.notificationTripTodoEmptyBody(flight),
    );
  }
  return (
    l10n.notificationTripTodoTitle,
    flight.isEmpty
        ? body
        : l10n.notificationTripTodoIncompleteBody(flight),
  );
}

(String title, String body)? _localizeDepartureSchedule(
  String type,
  String body,
  AppLocalizations l10n,
) {
  final flight = _parseFlightCode(body) ?? _parseFlightFromParens(body) ?? '';
  switch (type) {
    case 'flight_departure_6h':
      return (
        l10n.notificationDepartureScheduleTitle,
        flight.isEmpty
            ? body
            : l10n.notificationFlightDeparture6hBody(flight),
      );
    case 'home_departure_2h':
      return (
        l10n.notificationDepartureScheduleTitle,
        flight.isEmpty
            ? body
            : l10n.notificationHomeDeparture2hBody(flight),
      );
    case 'home_departure_30m':
      return (
        l10n.notificationDepartureScheduleTitle,
        flight.isEmpty
            ? body
            : l10n.notificationHomeDeparture30mBody(flight),
      );
    case 'home_departure_critical':
      return (
        l10n.notificationHomeDepartureCriticalTitle,
        flight.isEmpty
            ? body
            : l10n.notificationHomeDepartureCriticalBody(flight),
      );
    default:
      return null;
  }
}

(String title, String body)? _localizeDepartureAlert(
  String type,
  String title,
  String body,
  AppLocalizations l10n,
) {
  final flight = _parseFlightSuffix(title);
  if (flight == null) return null;

  final parsedBody = _parseDepartureBody(body);
  final localizedBody = parsedBody == null
      ? body
      : l10n.notificationDepartureBody(
          parsedBody.$1,
          parsedBody.$2,
          parsedBody.$3,
          parsedBody.$4,
          parsedBody.$5,
        );

  if (type.contains('departure_urgent') ||
      title.startsWith('Leave now!') ||
      title.startsWith('انطلق الآن!')) {
    return (l10n.notificationDepartureUrgent(flight), localizedBody);
  }
  if (type.contains('departure_warning') ||
      title.startsWith('You should leave soon') ||
      title.startsWith('يجب أن تنطلق قريباً')) {
    return (l10n.notificationDepartureWarning(flight), localizedBody);
  }
  if (type.contains('departure_reminder') ||
      title.startsWith('Gentle reminder') ||
      title.startsWith('تذكير لطيف')) {
    return (l10n.notificationDepartureReminder(flight), localizedBody);
  }
  return null;
}

String? _parseFlightCode(String text) {
  return _flightCodePattern.firstMatch(text)?.group(1);
}

String? _parseFlightFromParens(String text) {
  final match = RegExp(r'\(([A-Z]{2}\d+)\)').firstMatch(text);
  return match?.group(1);
}

String? _parseFlightSuffix(String title) {
  final parts = title.split('–');
  if (parts.length < 2) {
    final alt = title.split('-');
    if (alt.length < 2) return null;
    return alt.last.trim();
  }
  return parts.last.trim();
}

final _departureBodyPattern = RegExp(
  r'Your flight (.+?) departs at (\d{2}:\d{2})\. Recommended departure: (\d{2}:\d{2}) \((\d+) min travel, (\d+) min weather buffer\)\.',
);

final _departureBodyPatternAr = RegExp(
  r'رحلتك (.+?) تغادر الساعة (\d{2}:\d{2})\. المغادرة الموصى بها: (\d{2}:\d{2}) \((\d+) دقيقة سفر، (\d+) دقيقة احتياط للطقس\)\.',
);

(String flight, String dep, String leave, int travel, int buffer)?
    _parseDepartureBody(String body) {
  final match =
      _departureBodyPattern.firstMatch(body) ??
      _departureBodyPatternAr.firstMatch(body);
  if (match == null) return null;
  return (
    match.group(1)!,
    match.group(2)!,
    match.group(3)!,
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

bool _isPaymentSuccessful(String title) {
  final lower = title.toLowerCase();
  return lower == 'payment successful' || title == 'تم الدفع بنجاح';
}

bool _isPaymentFailed(String title) {
  final lower = title.toLowerCase();
  return lower == 'payment failed' || title == 'فشل الدفع';
}

bool _isPaymentRefunded(String title) {
  final lower = title.toLowerCase();
  return lower == 'payment refunded' || title == 'تم استرداد الدفع';
}

bool _isFullRefund(String title) {
  return title == 'استرداد كامل' || title.toLowerCase() == 'full refund';
}

bool _isPartialRefund(String title) {
  return title == 'استرداد جزئي' || title.toLowerCase() == 'partial refund';
}

bool _isBookingCanceled(String title) {
  return title == 'تم إلغاء الحجز' || title.toLowerCase() == 'booking canceled';
}

(String amount, String currency)? _parsePaymentAmount(String body) {
  final match = _paymentAmountPattern.firstMatch(body);
  if (match == null) return null;
  return (match.group(1)!.replaceAll(',', ''), match.group(2)!);
}
