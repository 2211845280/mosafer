import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TripStatus { confirmed, completed }

class Trip {
  final int reservationId;
  final String airline;
  final String imageLabel;
  final String fromCode;
  final String fromCity;
  final String toCode;
  final String toCity;
  final String dateTime;
  final String seat;
  final TripStatus status;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final String flightNumber;

  const Trip({
    this.reservationId = 0,
    required this.airline,
    required this.imageLabel,
    required this.fromCode,
    required this.fromCity,
    required this.toCode,
    required this.toCity,
    required this.dateTime,
    required this.seat,
    required this.status,
    this.departureAt,
    this.arrivalAt,
    this.flightNumber = '',
  });

  factory Trip.fromReservationJson(Map<String, dynamic> json) {
    final flight = json['flight'] as Map<String, dynamic>? ?? const {};
    final carrier = flight['carrier_code'] as String? ?? 'FL';
    final number = flight['flight_number'] as String? ?? '';
    final departure = DateTime.tryParse(
      flight['departure_at'] as String? ?? '',
    );
    final arrival = DateTime.tryParse(flight['arrival_at'] as String? ?? '');
    final status = (json['status'] as String? ?? '').toLowerCase();

    return Trip(
      reservationId: json['id'] as int? ?? 0,
      airline: '$carrier $number'.trim(),
      imageLabel: carrier.length > 2 ? carrier.substring(0, 2) : carrier,
      fromCode: flight['origin_iata'] as String? ?? '---',
      fromCity: flight['origin_iata'] as String? ?? 'Origin',
      toCode: flight['destination_iata'] as String? ?? '---',
      toCity: flight['destination_iata'] as String? ?? 'Destination',
      dateTime: _formatDateTime(departure),
      seat: 'Seat ${json['seat'] as String? ?? '--'}',
      status: status == 'completed' || status == 'cancelled' || status == 'canceled'
          ? TripStatus.completed
          : TripStatus.confirmed,
      departureAt: departure,
      arrivalAt: arrival,
      flightNumber: number,
    );
  }

  factory Trip.fromTicketScanJson(Map<String, dynamic> json) {
    final flight = json['flight'] as Map<String, dynamic>? ?? const {};
    final carrier = flight['carrier_code'] as String? ?? 'FL';
    final number = flight['flight_number'] as String? ?? '';
    final departure = DateTime.tryParse(
      flight['departure_at'] as String? ?? '',
    );
    final arrival = DateTime.tryParse(flight['arrival_at'] as String? ?? '');

    return Trip(
      reservationId: json['reservation_id'] as int? ?? 0,
      airline: '$carrier $number'.trim(),
      imageLabel: carrier.length > 2 ? carrier.substring(0, 2) : carrier,
      fromCode: flight['origin_iata'] as String? ?? '---',
      fromCity: flight['origin_iata'] as String? ?? 'Origin',
      toCode: flight['destination_iata'] as String? ?? '---',
      toCity: flight['destination_iata'] as String? ?? 'Destination',
      dateTime: _formatDateTime(departure),
      seat: 'Seat ${flight['seat'] as String? ?? '--'}',
      status: TripStatus.confirmed,
      departureAt: departure,
      arrivalAt: arrival,
      flightNumber: number,
    );
  }

  factory Trip.fromTicketImageScanJson(Map<String, dynamic> json) {
    final match = json['db_match'] as Map<String, dynamic>? ?? const {};
    final payload = match.isEmpty ? json : match;
    return Trip.fromTicketScanJson(payload);
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'confirmed';
    return Trip(
      reservationId: json['reservationId'] as int? ?? 0,
      airline: json['airline'] as String? ?? '',
      imageLabel: json['imageLabel'] as String? ?? '',
      fromCode: json['fromCode'] as String? ?? '---',
      fromCity: json['fromCity'] as String? ?? '',
      toCode: json['toCode'] as String? ?? '---',
      toCity: json['toCity'] as String? ?? '',
      dateTime: json['dateTime'] as String? ?? '',
      seat: json['seat'] as String? ?? '',
      status: statusRaw == 'completed'
          ? TripStatus.completed
          : TripStatus.confirmed,
      departureAt: DateTime.tryParse(json['departureAt'] as String? ?? ''),
      arrivalAt: DateTime.tryParse(json['arrivalAt'] as String? ?? ''),
      flightNumber: json['flightNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'airline': airline,
      'imageLabel': imageLabel,
      'fromCode': fromCode,
      'fromCity': fromCity,
      'toCode': toCode,
      'toCity': toCity,
      'dateTime': dateTime,
      'seat': seat,
      'status': status.name,
      'departureAt': departureAt?.toIso8601String(),
      'arrivalAt': arrivalAt?.toIso8601String(),
      'flightNumber': flightNumber,
    };
  }

  Trip copyWith({
    int? reservationId,
    String? airline,
    String? imageLabel,
    String? fromCode,
    String? fromCity,
    String? toCode,
    String? toCity,
    String? dateTime,
    String? seat,
    TripStatus? status,
    DateTime? departureAt,
    DateTime? arrivalAt,
    String? flightNumber,
  }) {
    return Trip(
      reservationId: reservationId ?? this.reservationId,
      airline: airline ?? this.airline,
      imageLabel: imageLabel ?? this.imageLabel,
      fromCode: fromCode ?? this.fromCode,
      fromCity: fromCity ?? this.fromCity,
      toCode: toCode ?? this.toCode,
      toCity: toCity ?? this.toCity,
      dateTime: dateTime ?? this.dateTime,
      seat: seat ?? this.seat,
      status: status ?? this.status,
      departureAt: departureAt ?? this.departureAt,
      arrivalAt: arrivalAt ?? this.arrivalAt,
      flightNumber: flightNumber ?? this.flightNumber,
    );
  }

  bool get isExpired {
    final departure = departureAt;
    if (departure == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final depDay = DateTime(departure.year, departure.month, departure.day);
    return depDay.isBefore(today);
  }

  bool get isUpcoming => status == TripStatus.confirmed && !isExpired;

  String formattedDeparture(Locale locale) {
    final departure = departureAt;
    if (departure == null) {
      return dateTime;
    }
    if (locale.languageCode == 'ar') {
      final day = DateFormat('d', 'en').format(departure);
      final month = DateFormat('MMM', 'ar').format(departure);
      final time = DateFormat('HH:mm', 'en').format(departure);
      return '$day $month، $time';
    }
    return DateFormat('d MMM, HH:mm', locale.toLanguageTag()).format(departure);
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Date pending';
  }
  final month = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month ${value.day}, $hour:$minute';
}
