import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';

class AirportExperiencePage extends ConsumerWidget {
  const AirportExperiencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);
    if (trip == null) {
      return const _AirportEmptyState();
    }

    return Scaffold(
      backgroundColor: _AirportColors.background,
      body: FutureBuilder<_AirportData>(
        future: _loadAirportData(ref, trip.reservationId, trip.fromCode),
        builder: (context, snapshot) {
          final data =
              snapshot.data ?? _AirportData.fromTripCode(trip.fromCode);
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(17, 16, 17, 190),
                    sliver: SliverList.list(
                      children: [
                        _ConciergeHeader(
                          onQrPressed: () => _showBoardingQr(context, ref),
                        ),
                        const SizedBox(height: 34),
                        _LiveExperienceIntro(
                          airportName: data.airportName,
                          terminal: data.terminal,
                        ),
                        const SizedBox(height: 25),
                        _GateSummary(
                          terminal: data.terminal,
                          gate: data.gate,
                          minutesToBoarding: data.minutesToBoarding,
                        ),
                        const SizedBox(height: 25),
                        _WalkStatusCard(
                          walkingMinutes: data.walkingMinutes,
                          gate: data.gate,
                        ),
                        const SizedBox(height: 27),
                        _AirportMapCard(gate: data.gate),
                        const SizedBox(height: 26),
                        _ShopSectionHeader(gate: data.gate),
                        const SizedBox(height: 13),
                        _ShopCards(shops: data.shops),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 17,
                right: 17,
                bottom: 96,
                child: _FixedAirportActions(gate: data.gate),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_AirportData> _loadAirportData(
    WidgetRef ref,
    int reservationId,
    String fromCode,
  ) async {
    final position = await LocationService().currentPosition();
    if (position == null) {
      return _AirportData.fromTripCode(fromCode);
    }
    final result = await ref
        .read(tripsRepositoryProvider)
        .airportDashboard(
          reservationId: reservationId,
          lat: position.latitude,
          lng: position.longitude,
        );
    return result.when(
      success: (data) =>
          _AirportData.fromDashboard(data, fallbackCode: fromCode),
      failure: (_) => _AirportData.fromTripCode(fromCode),
    );
  }

  void _showBoardingQr(BuildContext context, WidgetRef ref) {
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Open a trip first.')));
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: ref.read(tripsRepositoryProvider).getMyTickets(),
          builder: (context, snapshot) {
            String? payload;
            String? errorMessage;
            var hasTicketsForTrip = false;
            if (snapshot.hasError) {
              errorMessage = snapshot.error.toString();
            }
            if (snapshot.hasData) {
              final result = snapshot.data!;
              result.when(
                success: (tickets) {
                  for (final ticket in tickets) {
                    if (ticket['booking_id'] != trip.reservationId) continue;
                    hasTicketsForTrip = true;
                    final ticketNumber = ticket['ticket_number'] as String?;
                    if (ticketNumber != null && ticketNumber.isNotEmpty) {
                      payload = jsonEncode({'ticket_number': ticketNumber});
                      break;
                    }
                  }
                },
                failure: (error) => errorMessage = error,
              );
            }

            final body = switch (snapshot.connectionState) {
              ConnectionState.none ||
              ConnectionState.waiting ||
              ConnectionState.active => const CircularProgressIndicator(),
              ConnectionState.done =>
                errorMessage != null
                    ? Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _AirportColors.title),
                      )
                    : payload == null
                    ? Text(
                        hasTicketsForTrip
                            ? 'This booking has a ticket, but QR payload is invalid.'
                            : 'No boarding ticket found for the current booking.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _AirportColors.title),
                      )
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: QrImageView(
                          data: payload ?? '',
                          size: 210,
                          backgroundColor: Colors.white,
                        ),
                      ),
            };

            return AlertDialog(
              backgroundColor: _AirportColors.card,
              content: SizedBox(
                width: 240,
                height: 260,
                child: Center(child: body),
              ),
            );
          },
        );
      },
    );
  }
}

class _AirportData {
  final String airportName;
  final String terminal;
  final String gate;
  final int minutesToBoarding;
  final int walkingMinutes;
  final List<String> shops;

  const _AirportData({
    required this.airportName,
    required this.terminal,
    required this.gate,
    required this.minutesToBoarding,
    required this.walkingMinutes,
    required this.shops,
  });

  factory _AirportData.fromTripCode(String code) {
    return _AirportData(
      airportName: '${code.toUpperCase()} Airport',
      terminal: 'T1',
      gate: 'Gate --',
      minutesToBoarding: 0,
      walkingMinutes: 12,
      shops: const ['Airport Lounge', 'Coffee Shop'],
    );
  }

  factory _AirportData.fromDashboard(
    Map<String, dynamic> json, {
    required String fallbackCode,
  }) {
    final airport = json['airport'] as Map<String, dynamic>? ?? const {};
    final flight = json['flight_status'] as Map<String, dynamic>? ?? const {};
    return _AirportData(
      airportName:
          airport['name'] as String? ?? '${fallbackCode.toUpperCase()} Airport',
      terminal: flight['terminal']?.toString() ?? 'T1',
      gate: flight['departure_gate']?.toString() ?? 'Gate --',
      minutesToBoarding:
          (json['boarding']?['minutes_to_boarding'] as num?)?.toInt() ?? 0,
      walkingMinutes:
          (json['walking_time_to_gate_minutes'] as num?)?.toInt() ?? 12,
      shops:
          (json['nearby_food_shops'] as List?)
              ?.whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toList() ??
          const ['Airport Lounge', 'Coffee Shop'],
    );
  }
}

class _AirportEmptyState extends StatelessWidget {
  const _AirportEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _AirportColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Open a trip first to use Airport Experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AirportColors.title,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConciergeHeader extends StatelessWidget {
  final VoidCallback onQrPressed;

  const _ConciergeHeader({required this.onQrPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.flight_takeoff, color: _AirportColors.title, size: 22),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'The Concierge',
            style: TextStyle(
              color: _AirportColors.title,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.45,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onQrPressed,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _AirportColors.badge,
              shape: BoxShape.circle,
              border: Border.all(color: _AirportColors.border),
            ),
            child: const Icon(
              Icons.qr_code_2,
              color: _AirportColors.salmon,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveExperienceIntro extends StatelessWidget {
  final String airportName;
  final String terminal;

  const _LiveExperienceIntro({
    required this.airportName,
    required this.terminal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE EXPERIENCE',
                style: TextStyle(
                  color: _AirportColors.title,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome to\n$airportName • $terminal',
                style: const TextStyle(
                  color: _AirportColors.title,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                  letterSpacing: -0.55,
                ),
              ),
            ],
          ),
        ),
        _AirportStatusPill(),
      ],
    );
  }
}

class _AirportStatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _AirportColors.chip,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AirportColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: _AirportColors.title, size: 13),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'AT\nAIRPORT',
              style: TextStyle(
                color: _AirportColors.title,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GateSummary extends StatelessWidget {
  final String terminal;
  final String gate;
  final int minutesToBoarding;

  const _GateSummary({
    required this.terminal,
    required this.gate,
    required this.minutesToBoarding,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 91,
            decoration: BoxDecoration(
              color: _AirportColors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'TERMINAL',
                  style: TextStyle(
                    color: _AirportColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  terminal.replaceFirst('Terminal ', 'T'),
                  style: const TextStyle(
                    color: _AirportColors.title,
                    fontSize: 39,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: Container(
            height: 139,
            padding: const EdgeInsets.fromLTRB(18, 21, 18, 18),
            decoration: BoxDecoration(
              color: _AirportColors.blue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ASSIGNED GATE',
                  style: TextStyle(
                    color: _AirportColors.buttonText,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  gate,
                  style: const TextStyle(
                    color: _AirportColors.buttonText,
                    fontSize: 49,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -2,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: _AirportColors.buttonText,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Boarding in $minutesToBoarding min',
                      style: const TextStyle(
                        color: _AirportColors.buttonText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalkStatusCard extends StatelessWidget {
  final int walkingMinutes;
  final String gate;

  const _WalkStatusCard({required this.walkingMinutes, required this.gate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: _AirportColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: _AirportColors.brown,
                child: Icon(
                  Icons.directions_walk,
                  color: _AirportColors.salmon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated $walkingMinutes min walk',
                      style: const TextStyle(
                        color: _AirportColors.title,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Follow airport signs to $gate',
                      style: const TextStyle(
                        color: _AirportColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ProgressTrack(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'CURRENT LOCATION',
                style: TextStyle(
                  color: _AirportColors.muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                gate.toUpperCase(),
                style: const TextStyle(
                  color: _AirportColors.muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: const LinearProgressIndicator(
        minHeight: 4,
        value: 0.33,
        backgroundColor: _AirportColors.track,
        valueColor: AlwaysStoppedAnimation<Color>(_AirportColors.blue),
      ),
    );
  }
}

class _AirportMapCard extends StatelessWidget {
  final String gate;

  const _AirportMapCard({required this.gate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openMap(context, 'airport terminal'),
      child: Container(
        height: 195,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _AirportColors.map,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(painter: _MapGridPainter()),
              ),
            ),
            const Positioned(
              left: 61,
              top: 39,
              child: _MapPin(label: 'YOU', color: _AirportColors.salmon),
            ),
            Positioned(
              right: 70,
              top: 80,
              child: _MapPin(
                label: gate.toUpperCase(),
                color: _AirportColors.blue,
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: _MapActionButton(
                icon: Icons.open_in_full,
                label: 'EXPAND MAP',
                onTap: () => _openMap(context, gate),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: _RoundMapButton(
                onTap: () => _openMap(context, 'airport terminal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context, String destination) async {
    final opened = await MapsService().openDirections(destination: destination);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open maps on this device.')),
      );
    }
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = _AirportColors.gridDot
      ..style = PaintingStyle.fill;
    for (var y = 12.0; y < size.height; y += 16) {
      for (var x = 12.0; x < size.width; x += 19) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    final pathPaint = Paint()
      ..color = _AirportColors.path
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.35)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.5, size.height * 0.72)
      ..lineTo(size.width * 0.88, size.height * 0.72);
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  final String label;
  final Color color;

  const _MapPin({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.navigation, color: Colors.white, size: 8),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AirportColors.chip,
          foregroundColor: _AirportColors.title,
          elevation: 0,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 12),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RoundMapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: _AirportColors.chip,
        foregroundColor: _AirportColors.title,
        fixedSize: const Size(34, 34),
      ),
      icon: const Icon(Icons.layers_outlined, size: 17),
    );
  }
}

class _ShopSectionHeader extends StatelessWidget {
  final String gate;

  const _ShopSectionHeader({required this.gate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Shops near $gate',
            style: const TextStyle(
              color: _AirportColors.title,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Text(
          'SEE ALL',
          style: TextStyle(
            color: _AirportColors.title,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _ShopCards extends StatelessWidget {
  final List<String> shops;

  const _ShopCards({required this.shops});

  @override
  Widget build(BuildContext context) {
    final first = shops.isNotEmpty ? shops.first : 'Airport Lounge';
    final second = shops.length > 1 ? shops[1] : 'Coffee Shop';
    return Row(
      children: [
        Expanded(
          child: _ShopCard(
            title: first,
            subtitle: 'Near your gate',
            icon: Icons.location_city,
            gradient: const [Color(0xFF48B8A9), Color(0xFF4E2F25)],
            onTap: () {},
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: _ShopCard(
            title: second,
            subtitle: 'Open now',
            icon: Icons.checkroom,
            gradient: const [Color(0xFF0A0A0D), Color(0xFF18243A)],
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ShopCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 64,
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _AirportColors.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _AirportColors.title,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedAirportActions extends StatelessWidget {
  final String gate;

  const _FixedAirportActions({required this.gate});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _AirportColors.salmon,
              foregroundColor: _AirportColors.buttonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(
              'Proceed to $gate',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _AirportColors {
  _AirportColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color chip = Color(0xFF26364F);
  static const Color badge = Color(0xFF172844);
  static const Color border = Color(0xFF314663);
  static const Color map = Color(0xFF07172D);
  static const Color track = Color(0xFF2B3E5A);
  static const Color path = Color(0xFF0E2745);
  static const Color gridDot = Color(0xFF112B4A);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF77879E);
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFACA6);
  static const Color brown = Color(0xFF5B332F);
  static const Color buttonText = Color(0xFF061326);
}
