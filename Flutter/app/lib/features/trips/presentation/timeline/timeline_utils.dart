import '../../domain/ai_travel.dart';

int? daysUntilDeparture(DateTime? departureAt) {
  if (departureAt == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dep = DateTime(
    departureAt.year,
    departureAt.month,
    departureAt.day,
  );
  return dep.difference(today).inDays;
}

bool isTimelineItemVisible(TimelineItem item, int? daysUntil) {
  if (daysUntil == null) return true;
  if (daysUntil < 0) return item.daysBefore == 0;
  return item.daysBefore <= daysUntil;
}

String timelineTodoMatchKey({required String title, required String category}) {
  final normalizedCategory =
      category.trim().isEmpty ? 'task' : category.trim().toLowerCase();
  return '${title.trim().toLowerCase()}|$normalizedCategory';
}

String timelineTodoMatchKeyForItem(TimelineItem item) {
  return timelineTodoMatchKey(title: item.title, category: item.category);
}
