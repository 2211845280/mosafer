import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/notifications/presentation/notification_push_listener.dart';
import '../../features/notifications/presentation/notifications_controller.dart';
import '../../l10n/app_localizations.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  NotificationPushListener? _pushListener;

  @override
  void initState() {
    super.initState();
    _pushListener = NotificationPushListener(
      onReload: ref.read(notificationsControllerProvider.notifier).load,
    )..start();
  }

  @override
  void dispose() {
    _pushListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsControllerProvider);
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);

    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndexFor(location);
    final usesCustomAppBar =
        location == '/plan-departure' || location == '/settings';
    final usesSettingsAction = location == '/profile';
    final showsDashboardBackButton =
        location == '/dashboard' ||
        location == '/on-way' ||
        location == '/settings' ||
        location == '/ticket-details' ||
        location == '/packing' ||
        location == '/timeline' ||
        location == '/trip-todos' ||
        location == '/airport-experience';
    final backRouteName = location == '/dashboard'
        ? 'myTrips'
        : location == '/settings'
        ? 'profile'
        : 'dashboard';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              if (!usesCustomAppBar)
                SafeArea(
                  bottom: false,
                  child: _ShellAppBar(
                    l10n: AppLocalizations.of(context)!,
                    showBackButton: showsDashboardBackButton,
                    backRouteName: backRouteName,
                    showSettingsAction: usesSettingsAction,
                    hasUnreadNotifications: hasUnread,
                  ),
                ),
              Expanded(child: widget.child),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _BottomNavigation(
                l10n: AppLocalizations.of(context)!,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    _goToDestination(context, index, selectedIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndexFor(String location) {
    if (location.startsWith('/profile') || location.startsWith('/settings')) {
      return 2;
    }
    if (location.startsWith('/trips')) {
      return 1;
    }
    if (location.startsWith('/dashboard') ||
        location.startsWith('/on-way') ||
        location.startsWith('/plan-departure') ||
        location.startsWith('/ticket-details') ||
        location.startsWith('/packing') ||
        location.startsWith('/timeline') ||
        location.startsWith('/trip-todos') ||
        location.startsWith('/airport-experience')) {
      return 1;
    }
    return 0;
  }

  void _goToDestination(BuildContext context, int index, int selectedIndex) {
    if (index == selectedIndex) {
      return;
    }

    switch (index) {
      case 0:
        context.goNamed('explore');
        return;
      case 1:
        context.goNamed('myTrips');
        return;
      case 2:
        context.goNamed('profile');
        return;
    }
  }
}

class _ShellAppBar extends StatelessWidget {
  final AppLocalizations l10n;
  final bool showBackButton;
  final String backRouteName;
  final bool showSettingsAction;
  final bool hasUnreadNotifications;

  const _ShellAppBar({
    required this.l10n,
    required this.showBackButton,
    required this.backRouteName,
    this.showSettingsAction = false,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 17, 14, 0),
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.goNamed(backRouteName),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Icon(
                    Icons.arrow_back,
                    color: _ShellColors.title,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              l10n.brandMosafer,
              style: const TextStyle(
                color: _ShellColors.title,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: showSettingsAction
                ? () => context.goNamed('settings')
                : () => context.pushNamed('notifications'),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      showSettingsAction
                          ? Icons.settings_outlined
                          : Icons.notifications_none_outlined,
                      color: _ShellColors.icon,
                      size: 22,
                    ),
                  ),
                  if (!showSettingsAction && hasUnreadNotifications)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _ShellColors.coral,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final AppLocalizations l10n;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BottomNavigation({
    required this.l10n,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 10),
      decoration: const BoxDecoration(
        color: AppColors.nav,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.airplane_ticket_outlined,
              label: l10n.navFlights,
              isSelected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NavigationItem(
              icon: Icons.work_outline,
              label: l10n.navMyTrips,
              isSelected: selectedIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NavigationItem(
              icon: Icons.person_outline,
              label: l10n.navProfile,
              isSelected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.background : _ShellColors.icon,
              size: 20,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.background : _ShellColors.icon,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellColors {
  _ShellColors._();

  static const Color title = AppColors.onBackground;
  static const Color icon = AppColors.onSurfaceVariant;
  static const Color coral = AppColors.secondary;
}
