import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../shared/models/result.dart';
import '../domain/ai_travel.dart';
import '../domain/trip.dart';
import 'airport_name_resolver.dart';

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository(ref.watch(apiClientProvider));
});

class TripTodoDraft {
  final String title;
  final String? sourceKey;
  final String? titleAr;
  final String? titleEn;

  const TripTodoDraft({
    required this.title,
    this.sourceKey,
    this.titleAr,
    this.titleEn,
  });
}

class TripsRepository {
  final ApiClient _apiClient;
  late final AirportNameResolver _airportNames;

  TripsRepository(this._apiClient) {
    _airportNames = AirportNameResolver(_apiClient);
  }

  Future<Result<List<Trip>>> getMyTrips() async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/reservations/me',
        queryParameters: {'page': 1, 'page_size': 50},
      );
      final items = _extractListFromPayload(response.data);
      final trips = <Trip>[];
      for (final item in items) {
        final json = _asJsonMap(item);
        if (json == null) continue;
        final status = (json['status'] as String? ?? '').toLowerCase();
        if (status == 'canceled' || status == 'cancelled') {
          continue;
        }
        trips.add(Trip.fromReservationJson(json));
      }
      final enriched = await _enrichAirportNames(trips);
      return Success(enriched);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<Trip>> scanQr(String qrPayload) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/tickets/scan',
        data: {'qr_payload': qrPayload},
      );
      return Success(Trip.fromTicketScanJson(response.data ?? const {}));
    } catch (e) {
      final message = _message(e).toLowerCase();
      if (message.contains('ticket not found')) {
        return const Failure('scan:ticket_not_found');
      }
      if (message.contains('qr payload does not contain')) {
        return const Failure('scan:invalid_ticket');
      }
      return Failure(_message(e));
    }
  }

  Future<Result<Trip>> scanTicketImage(XFile image) async {
    try {
      final response = await _apiClient.multipart<Map<String, dynamic>>(
        '/tickets/scan-image',
        data: FormData.fromMap({
          'file': await _multipartFileFromImage(image),
        }),
      );
      final data = response.data ?? const {};
      if (data['decision'] != 'valid_ticket') {
        return Failure(_scanImageFailureCode(data));
      }
      return Success(Trip.fromTicketImageScanJson(data));
    } catch (e) {
      final raw = e.toString().toLowerCase();
      if (kIsWeb &&
          (raw.contains('multipartfile') ||
              raw.contains('dart:io') ||
              raw.contains('unsupported operation'))) {
        return const Failure('scan:image_upload');
      }
      return Failure(_message(e));
    }
  }

  Future<Result<void>> claimTicket(String ticketNumber) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/tickets/claim',
        data: {'ticket_number': ticketNumber},
      );
      return const Success<void>(null);
    } catch (e) {
      final message = _message(e).toLowerCase();
      if (message.contains('already assigned to another account')) {
        return const Failure('scan:ticket_already_assigned');
      }
      return Failure(_message(e));
    }
  }

  Future<MultipartFile> _multipartFileFromImage(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      final name = image.name.isNotEmpty ? image.name : 'ticket.jpg';
      return MultipartFile.fromBytes(bytes, filename: name);
    }

    final path = image.path;
    if (path.isNotEmpty) {
      return MultipartFile.fromFile(
        path,
        filename: image.name.isNotEmpty ? image.name : null,
      );
    }

    final bytes = await image.readAsBytes();
    final name = image.name.isNotEmpty ? image.name : 'ticket.jpg';
    return MultipartFile.fromBytes(bytes, filename: name);
  }

  String _scanImageFailureCode(Map<String, dynamic> data) {
    final decision = data['decision']?.toString() ?? 'invalid_ticket';
    if (decision == 'expired_ticket') {
      return 'scan:expired_ticket';
    }

    final warnings = data['warnings'];
    if (warnings is List) {
      for (final warning in warnings) {
        final text = warning.toString().toLowerCase();
        if (text.contains('no matching ticket')) {
          return 'scan:ticket_not_found';
        }
        if (text.contains('does not look like a valid ticket')) {
          return 'scan:invalid_ticket';
        }
        if (text.contains('ticket number could not be detected')) {
          return 'scan:invalid_ticket';
        }
      }
    }

    return 'scan:$decision';
  }

  Future<Result<List<Map<String, dynamic>>>> getMyTickets() async {
    try {
      final response = await _apiClient.get<dynamic>('/tickets');
      return Success(
        _extractListFromPayload(
          response.data,
        ).map(_asJsonMap).whereType<Map<String, dynamic>>().toList(),
      );
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<Map<String, dynamic>>> getDeparturePlan({
    required int reservationId,
    double? lat,
    double? lng,
    String mode = 'driving',
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trips/$reservationId/departure-plan',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          'mode': mode,
        },
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<Map<String, dynamic>>> locationCheck({
    required int reservationId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/trips/$reservationId/location-check',
        data: {'lat': lat, 'lng': lng},
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<Map<String, dynamic>>> airportDashboard({
    required int reservationId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trips/$reservationId/airport-dashboard',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<Map<String, dynamic>>> airportIndoorMap({
    required int reservationId,
    String? gate,
    String? highlight,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trips/$reservationId/airport-indoor-map',
        queryParameters: {
          if (gate != null && gate.isNotEmpty) 'gate': gate,
          if (highlight != null && highlight.isNotEmpty) 'highlight': highlight,
        },
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<PackingListResult>> fetchPackingList(int reservationId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/trips/$reservationId/packing-list',
      );
      return Success(
        PackingListResult.fromJson(response.data ?? const {}),
      );
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<TimelineResult>> fetchTimeline(int reservationId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/trips/$reservationId/timeline',
      );
      return Success(TimelineResult.fromJson(response.data ?? const {}));
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<int>> populateTodosFromPacking(int reservationId) async {
    try {
      final response = await _apiClient.post<List<dynamic>>(
        '/trips/$reservationId/todos/populate',
      );
      return Success((response.data ?? const []).length);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getTodos(int reservationId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/trips/$reservationId/todos',
      );
      return Success(
        (response.data ?? const []).whereType<Map<String, dynamic>>().toList(),
      );
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<Map<String, dynamic>>> createTodo({
    required int reservationId,
    required String title,
    String category = 'task',
    String priority = 'recommended',
    String? sourceKey,
    String? titleAr,
    String? titleEn,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/trips/$reservationId/todos',
        data: {
          'title': title,
          'category': category,
          'priority': priority,
          if (sourceKey != null && sourceKey.isNotEmpty)
            'source_key': sourceKey,
          if (titleAr != null && titleAr.isNotEmpty) 'title_ar': titleAr,
          if (titleEn != null && titleEn.isNotEmpty) 'title_en': titleEn,
        },
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<int>> createTodos({
    required int reservationId,
    required List<TripTodoDraft> todos,
    String category = 'task',
    String priority = 'recommended',
  }) async {
    var created = 0;
    for (final todo in todos.where((value) => value.title.trim().isNotEmpty)) {
      final result = await createTodo(
        reservationId: reservationId,
        title: todo.title.trim(),
        category: category,
        priority: priority,
        sourceKey: todo.sourceKey,
        titleAr: todo.titleAr,
        titleEn: todo.titleEn,
      );
      if (result is Failure<Map<String, dynamic>>) {
        return Failure(result.error);
      }
      created++;
    }
    return Success(created);
  }

  Future<Result<Map<String, dynamic>>> updateTodo({
    required int reservationId,
    required int todoId,
    String? title,
    String? category,
    String? priority,
    bool? isCompleted,
  }) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/trips/$reservationId/todos/$todoId',
        data: {
          if (title != null) 'title': title,
          if (category != null) 'category': category,
          if (priority != null) 'priority': priority,
          if (isCompleted != null) 'is_completed': isCompleted,
        },
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<void>> deleteTodo({
    required int reservationId,
    required int todoId,
  }) async {
    try {
      await _apiClient.delete<void>('/trips/$reservationId/todos/$todoId');
      return const Success(null);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<int>> deleteTodos({
    required int reservationId,
    required List<int> todoIds,
  }) async {
    var deleted = 0;
    for (final todoId in todoIds) {
      final result = await deleteTodo(
        reservationId: reservationId,
        todoId: todoId,
      );
      if (result is Failure<void>) {
        return Failure(result.error);
      }
      deleted++;
    }
    return Success(deleted);
  }

  String _message(Object error) => apiErrorMessage(error);

  Future<List<Trip>> _enrichAirportNames(List<Trip> trips) async {
    if (trips.isEmpty) {
      return trips;
    }
    final codes = trips.expand((trip) => [trip.fromCode, trip.toCode]);
    final names = await _airportNames.resolveMany(codes);
    return trips
        .map(
          (trip) => trip.copyWith(
            fromCity: names[trip.fromCode.toUpperCase()] ?? trip.fromCode,
            toCity: names[trip.toCode.toUpperCase()] ?? trip.toCode,
          ),
        )
        .toList();
  }

  List<dynamic> _extractListFromPayload(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      for (final key in const [
        'items',
        'data',
        'results',
        'reservations',
        'trips',
      ]) {
        final value = payload[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic>? _asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }
}
