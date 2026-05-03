import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/explore/presentation/explore_page.dart';
import '../../features/auth/presentation/login/login_page.dart';
import '../../features/auth/presentation/register/register_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/profile/presentation/change_password/change_password_page.dart';
import '../../features/profile/presentation/edit_profile/edit_profile_page.dart';
import '../../features/profile/presentation/notification_settings/notification_settings_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/settings/settings_page.dart';
import '../../features/trips/presentation/airport_experience/airport_experience_page.dart';
import '../../features/trips/presentation/my_trips/my_trips_page.dart';
import '../../features/trips/presentation/on_way/on_way_page.dart';
import '../../features/trips/presentation/packing/packing_page.dart';
import '../../features/trips/presentation/plan_departure/plan_departure_page.dart';
import '../../features/trips/presentation/scan/scan_page.dart';
import '../../features/trips/presentation/ticket_details/ticket_details_page.dart';
import '../../features/trips/presentation/timeline/timeline_page.dart';
import '../../features/trips/presentation/todos/trip_todos_page.dart';
import '../../shared/navigation/app_shell.dart';
import '../../features/auth/presentation/auth_session_controller.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionControllerProvider);
  return AppRouter.router(session);
});

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthSessionState session) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';

      if (session.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      if (!session.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (location == '/splash' || isAuthRoute) {
        return '/trips';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => const ExplorePage(),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/on-way',
            name: 'onWay',
            builder: (context, state) => const OnWayPage(),
          ),
          GoRoute(
            path: '/plan-departure',
            name: 'planDeparture',
            builder: (context, state) => const PlanDeparturePage(),
          ),
          GoRoute(
            path: '/ticket-details',
            name: 'ticketDetails',
            builder: (context, state) => const TicketDetailsPage(),
          ),
          GoRoute(
            path: '/packing',
            name: 'packing',
            builder: (context, state) => const PackingPage(),
          ),
          GoRoute(
            path: '/timeline',
            name: 'timeline',
            builder: (context, state) => const TimelinePage(),
          ),
          GoRoute(
            path: '/trip-todos',
            name: 'tripTodos',
            builder: (context, state) => const TripTodosPage(),
          ),
          GoRoute(
            path: '/airport-experience',
            name: 'airportExperience',
            builder: (context, state) => const AirportExperiencePage(),
          ),
          GoRoute(
            path: '/trips',
            name: 'myTrips',
            builder: (context, state) => const MyTripsPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
