import '../../domain/ai_travel.dart';
import '../../../../l10n/app_localizations.dart';

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

int? hoursUntilDeparture(DateTime? departureAt) {
  if (departureAt == null) return null;
  final diff = departureAt.difference(DateTime.now());
  if (diff.isNegative) return 0;
  return diff.inHours;
}

String timelineOffsetLabel(
  AppLocalizations l10n,
  int daysBefore,
  DateTime? departureAt,
) {
  final hoursLeft = hoursUntilDeparture(departureAt);
  if (hoursLeft != null && hoursLeft < 24) {
    if (hoursLeft <= 1) {
      return l10n.timelineHourBefore;
    }
    return l10n.timelineHoursBefore(hoursLeft);
  }

  return switch (daysBefore) {
    14 => l10n.timelineDay14,
    7 => l10n.timelineDay7,
    1 => l10n.timelineDay1,
    0 => l10n.timelineDay0,
    _ => l10n.timelineDayBefore(daysBefore),
  };
}

String timelineTodoMatchKeyForItem(TimelineItem item) {
  return timelineTodoMatchKey(title: item.title, category: item.category);
}
