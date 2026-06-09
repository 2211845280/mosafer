import '../../../l10n/app_localizations.dart';

String formatNotificationTimeAgo(DateTime createdAt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) {
    return l10n.timeAgoNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.timeAgoMinutes(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.timeAgoHours(diff.inHours);
  }
  return l10n.timeAgoDays(diff.inDays);
}
