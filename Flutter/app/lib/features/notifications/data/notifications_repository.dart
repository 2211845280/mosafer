import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/result.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository(this._apiClient);

  Future<Result<List<Map<String, dynamic>>>> getNotifications() async {
    try {
      final response = await _apiClient.get<dynamic>('/notifications');
      return Success(
        _extractItems(
          response.data,
        ).map(_asJsonMap).whereType<Map<String, dynamic>>().toList(),
      );
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<void>> markAllRead() async {
    try {
      await _apiClient.post<Map<String, dynamic>>('/notifications/read-all');
      return const Success(null);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<void>> markRead(List<int> ids) async {
    if (ids.isEmpty) return const Success(null);
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/notifications/read',
        data: {'ids': ids},
      );
      return const Success(null);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<void>> deleteNotification(int id) async {
    try {
      await _apiClient.delete<dynamic>('/notifications/$id');
      return const Success(null);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<void>> registerCurrentDevice() async {
    if (kIsWeb) return const Success(null);

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        return const Success(null);
      }
      await _apiClient.post<Map<String, dynamic>>(
        '/devices/register',
        data: {
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
        },
      );
      return const Success(null);
    } catch (e) {
      // Push configuration can be missing in development; in-app notifications
      // still work through the REST API.
      return Failure(_message(e));
    }
  }

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final items = payload['items'];
      if (items is List) return items;
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

  String _message(Object error) {
    return error.toString().replaceFirst('DioException [bad response]: ', '');
  }
}
