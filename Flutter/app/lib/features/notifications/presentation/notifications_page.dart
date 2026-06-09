import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/error_message_localizer.dart';
import '../../../l10n/app_localizations.dart';
import 'notification_time_format.dart';
import 'notifications_controller.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _NotificationColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationsAppBar(l10n: l10n, onReadAll: controller.markAllRead),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _NotificationsMessage(
                  message: localizeUserFacingError(error, l10n),
                  onRetry: controller.load,
                  retryLabel: l10n.retry,
                ),
                data: (notifications) {
                  final today = notifications
                      .where((item) => item.isToday)
                      .toList();
                  final earlier = notifications
                      .where((item) => !item.isToday)
                      .toList();
                  if (notifications.isEmpty) {
                    return _NotificationsMessage(
                      message: l10n.notificationsNoYet,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(17, 15, 17, 34),
                          sliver: SliverList.list(
                            children: [
                              if (today.isNotEmpty)
                                _NotificationSectionBlock(
                                  l10n: l10n,
                                  title: l10n.notificationsToday,
                                  notifications: today,
                                ),
                              if (today.isNotEmpty && earlier.isNotEmpty)
                                const SizedBox(height: 27),
                              if (earlier.isNotEmpty)
                                _NotificationSectionBlock(
                                  l10n: l10n,
                                  title: l10n.notificationsEarlier,
                                  notifications: earlier,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsAppBar extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onReadAll;

  const _NotificationsAppBar({required this.l10n, required this.onReadAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 17, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back,
                  color: _NotificationColors.title,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.brandMosafer,
              style: const TextStyle(
                color: _NotificationColors.title,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onReadAll,
            style: TextButton.styleFrom(
              foregroundColor: _NotificationColors.title,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              l10n.notificationsReadAll,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSectionBlock extends StatelessWidget {
  final AppLocalizations l10n;
  final String title;
  final List<AppNotification> notifications;

  const _NotificationSectionBlock({
    required this.l10n,
    required this.title,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 7),
          child: Text(
            title,
            style: const TextStyle(
              color: _NotificationColors.sectionTitle,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...notifications.map(
          (notification) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _NotificationCard(l10n: l10n, notification: notification),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppNotification notification;

  const _NotificationCard({required this.l10n, required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final iconColor = isUnread
        ? _NotificationColors.blue
        : _NotificationColors.readIcon;

    return Container(
      constraints: const BoxConstraints(minHeight: 91),
      padding: const EdgeInsets.fromLTRB(17, 16, 16, 15),
      decoration: BoxDecoration(
        color: _NotificationColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _NotificationColors.border),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: _NotificationColors.blue.withValues(alpha: 0.11),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isUnread ? 0.23 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: isUnread
                              ? _NotificationColors.title
                              : _NotificationColors.readTitle,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatNotificationTimeAgo(notification.createdAt, l10n),
                      style: const TextStyle(
                        color: _NotificationColors.muted,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.body,
                        style: TextStyle(
                          color: isUnread
                              ? _NotificationColors.title
                              : _NotificationColors.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _UnreadIndicator(isUnread: isUnread),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadIndicator extends StatelessWidget {
  final bool isUnread;

  const _UnreadIndicator({required this.isUnread});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isUnread
            ? _NotificationColors.unreadDot
            : _NotificationColors.readDot,
        shape: BoxShape.circle,
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: _NotificationColors.unreadDot.withValues(alpha: 0.55),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _NotificationsMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const _NotificationsMessage({
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _NotificationColors.title,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationColors {
  _NotificationColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color border = Color(0xFF1F344F);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFFACBAD1);
  static const Color muted = Color(0xFF7386A0);
  static const Color sectionTitle = Color(0xFF9FB0CE);
  static const Color readTitle = Color(0xFFB8C5DA);
  static const Color readIcon = Color(0xFF8795AA);
  static const Color readDot = Color(0xFF33445F);
  static const Color unreadDot = Color(0xFFAEC8FF);
  static const Color blue = Color(0xFF4A91F8);
  // ignore: unused_field
  static const Color salmon = Color(0xFFFFA982);
}
