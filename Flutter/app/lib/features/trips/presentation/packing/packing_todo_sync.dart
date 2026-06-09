import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trips_repository.dart';

String normalizePackingTodoTitle(String title) => title.trim().toLowerCase();

class PackingTodoSyncNotifier extends Notifier<Map<int, Set<String>>> {
  @override
  Map<int, Set<String>> build() => {};

  Set<String> titlesFor(int reservationId) =>
      state[reservationId] ?? const {};

  Future<void> refreshFromServer(int reservationId) async {
    final result = await ref
        .read(tripsRepositoryProvider)
        .getTodos(reservationId);
    result.when(
      success: (items) {
        final titles = items
            .where(
              (item) =>
                  (item['category'] as String? ?? '').toLowerCase() ==
                  'packing',
            )
            .map(
              (item) => normalizePackingTodoTitle(
                item['title'] as String? ?? '',
              ),
            )
            .where((title) => title.isNotEmpty)
            .toSet();
        state = {...state, reservationId: titles};
      },
      failure: (_) {},
    );
  }

  void markAdded(int reservationId, Iterable<String> titles) {
    final normalized = titles
        .map(normalizePackingTodoTitle)
        .where((title) => title.isNotEmpty);
    final current = {...(state[reservationId] ?? const {})}..addAll(normalized);
    state = {...state, reservationId: current};
  }

  void markRemoved(int reservationId, String title) {
    final key = normalizePackingTodoTitle(title);
    if (key.isEmpty) return;
    final current = {...(state[reservationId] ?? const {})}..remove(key);
    state = {...state, reservationId: current};
  }
}

final packingTodoSyncProvider =
    NotifierProvider<PackingTodoSyncNotifier, Map<int, Set<String>>>(
  PackingTodoSyncNotifier.new,
);

final packingTodoTitlesForProvider = Provider.family<Set<String>, int>(
  (ref, reservationId) =>
      ref.watch(packingTodoSyncProvider)[reservationId] ?? const {},
);
