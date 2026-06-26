import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/error_message_localizer.dart';
import '../../../core/localization/notification_message_localizer.dart';
import '../../../l10n/app_localizations.dart';
import 'notification_time_format.dart';
import 'notifications_controller.dart';
import '../../../core/theme/app_theme_extension.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colors.background,
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
                                  controller: controller,
                                ),
                              if (today.isNotEmpty && earlier.isNotEmpty)
                                const SizedBox(height: 27),
                              if (earlier.isNotEmpty)
                                _NotificationSectionBlock(
                                  l10n: l10n,
                                  title: l10n.notificationsEarlier,
                                  notifications: earlier,
                                  controller: controller,
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
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 17, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back,
                  color: colors.title,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.brandMosafer,
              style: TextStyle(
                color: colors.title,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onReadAll,
            style: TextButton.styleFrom(
              foregroundColor: colors.title,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              l10n.notificationsReadAll,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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
  final NotificationsController controller;

  const _NotificationSectionBlock({
    required this.l10n,
    required this.title,
    required this.notifications,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 7),
          child: Text(
            title,
            style: TextStyle(
              color: colors.section,
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
            child: _NotificationCard(
              l10n: l10n,
              notification: notification,
              onTap: () => controller.markRead(notification.id),
              onDelete: () => _confirmDelete(context, notification.id),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.notificationsDelete),
        content: Text(l10n.notificationsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notificationsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.notificationsDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteNotification(id);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.l10n,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUnread = !notification.read;
    final iconColor = isUnread
        ? colors.primary
        : colors.readIcon;
    final localized = localizeNotification(notification, l10n);

    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 91),
        padding: const EdgeInsets.fromLTRB(17, 16, 16, 15),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.11),
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
                          localized.$1,
                          style: TextStyle(
                            color: isUnread
                                ? colors.title
                                : colors.readTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatNotificationTimeAgo(notification.createdAt, l10n),
                        style: TextStyle(
                          color: colors.muted,
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
                          localized.$2,
                          style: TextStyle(
                            color: isUnread
                                ? colors.title
                                : colors.body,
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
      ),
    );

    return Dismissible(
      key: ValueKey('notification-${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_outline, color: colors.primary),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: card,
    );
  }
}

class _UnreadIndicator extends StatelessWidget {
  final bool isUnread;

  const _UnreadIndicator({required this.isUnread});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isUnread
            ? colors.unreadDot
            : colors.readDot,
        shape: BoxShape.circle,
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: colors.unreadDot.withValues(alpha: 0.55),
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
    final colors = context.colors;
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
              style: TextStyle(
                color: colors.title,
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
