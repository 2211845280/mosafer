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
      status: status == 'completed' || status == 'cancelled'
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

  bool get isUpcoming => status == TripStatus.confirmed;
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
