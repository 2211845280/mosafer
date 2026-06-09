import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';

final notificationsControllerProvider =
    StateNotifierProvider.autoDispose<
      NotificationsController,
      AsyncValue<List<AppNotification>>
    >(
      (ref) =>
          NotificationsController(ref.watch(notificationsRepositoryProvider))
            ..load(),
    );

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final state = ref.watch(notificationsControllerProvider);
  return state.maybeWhen(
    data: (items) => items.any((notification) => !notification.read),
    orElse: () => false,
  );
});

class NotificationsController
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationsRepository _repository;

  NotificationsController(this._repository) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await _repository.getNotifications();
    state = result.when(
      success: (items) =>
          AsyncValue.data(items.map(AppNotification.fromJson).toList()),
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? const [];
    state = AsyncValue.data(
      current.map((notification) => notification.copyWith(read: true)).toList(),
    );
    final result = await _repository.markAllRead();
    result.when(
      success: (_) {},
      failure: (error) => state = AsyncValue.error(error, StackTrace.current),
    );
  }

  Future<void> registerDeviceForPush() async {
    await _repository.registerCurrentDevice();
  }
}

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'trip',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  IconData get icon {
    final lower = type.toLowerCase();
    if (lower.contains('gate')) return Icons.airline_stops;
    if (lower.contains('boarding')) return Icons.flight_takeoff;
    if (lower.contains('check')) return Icons.fact_check_outlined;
    return Icons.notifications_none_outlined;
  }

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }
}
