import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/result.dart';
import '../domain/ai_travel.dart';
import '../domain/trip.dart';
import 'airport_name_resolver.dart';

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository(ref.watch(apiClientProvider));
});

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
      return Failure(_message(e));
    }
  }

  Future<Result<Trip>> scanTicketImage(String imagePath) async {
    try {
      final response = await _apiClient.multipart<Map<String, dynamic>>(
        '/tickets/scan-image',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(imagePath),
        }),
      );
      final data = response.data ?? const {};
      if (data['decision'] != 'valid_ticket') {
        return Failure(data['decision']?.toString() ?? 'Invalid ticket image.');
      }
      return Success(Trip.fromTicketImageScanJson(data));
    } catch (e) {
      return Failure(_message(e));
    }
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
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/trips/$reservationId/todos',
        data: {'title': title, 'category': category, 'priority': priority},
      );
      return Success(response.data ?? const {});
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<int>> createTodos({
    required int reservationId,
    required List<String> titles,
    String category = 'task',
    String priority = 'recommended',
  }) async {
    var created = 0;
    for (final title
        in titles
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)) {
      final result = await createTodo(
        reservationId: reservationId,
        title: title,
        category: category,
        priority: priority,
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

  String _message(Object error) {
    return error.toString().replaceFirst('DioException [bad response]: ', '');
  }

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
