import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/explore/presentation/explore_page.dart';
import 'package:app/features/auth/presentation/login/login_page.dart';
import 'package:app/features/auth/presentation/register/register_page.dart';
import 'package:app/features/trips/domain/trip.dart';
import 'package:app/features/trips/presentation/active_trip_controller.dart';
import 'package:app/shared/navigation/app_shell.dart';

void main() {
  testWidgets('Login page renders Mosafer identity', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(find.text('MOSAFER'), findsOneWidget);
    expect(find.text('YOUR DIGITAL CURATOR FOR THE UNKNOWN'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('SECURITY KEY'), findsOneWidget);
    expect(find.text('Login to Mosafer'), findsOneWidget);
  });

  testWidgets('Register route opens from login page', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
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
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    final registerLink = find.text('Register Now');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Start your journey.'), findsOneWidget);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
  });

  testWidgets('Shell shows brand and navigation', (tester) async {
    await tester.pumpWidget(_testShell(initialLocation: '/explore'));

    expect(find.text('MOSAFER'), findsOneWidget);
    expect(find.text('Flights'), findsOneWidget);
    expect(find.text('OPEN BOOKING WEBSITE'), findsOneWidget);
    expect(find.text('FLIGHTS'), findsOneWidget);
    expect(find.text('MY TRIPS'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });

  testWidgets('Dashboard renders active trip UX', (tester) async {
    await tester.pumpWidget(
      _testShell(
        initialLocation: '/dashboard',
        overrides: [activeTripProvider.overrideWith((ref) => _sampleTrip)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MOSAFER'), findsOneWidget);
    expect(find.text('SkyLink 442'), findsOneWidget);
    expect(find.text('LHR'), findsOneWidget);
    expect(find.text('DXB'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Departure Plan'), findsOneWidget);
  });
}

Widget _testShell({
  required String initialLocation,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
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
            path: '/trips',
            name: 'myTrips',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Trips test placeholder')),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Profile test placeholder')),
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Notifications test placeholder')),
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

const _sampleTrip = Trip(
  reservationId: 1,
  airline: 'SkyLink 442',
  imageLabel: 'SK',
  fromCode: 'LHR',
  fromCity: 'LONDON',
  toCode: 'DXB',
  toCity: 'DUBAI',
  dateTime: 'Nov 12, 08:15',
  seat: 'Seat 12A',
  status: TripStatus.confirmed,
  flightNumber: '442',
);
