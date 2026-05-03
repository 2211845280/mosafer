import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../active_trip_controller.dart';
import '../trip_stage_controller.dart';

class PlanDeparturePage extends ConsumerStatefulWidget {
  const PlanDeparturePage({super.key});

  @override
  ConsumerState<PlanDeparturePage> createState() => _PlanDeparturePageState();
}

class _PlanDeparturePageState extends ConsumerState<PlanDeparturePage> {
  bool _requestedPlan = false;
  String _selectedMode = 'driving';

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    final stageState = ref.watch(tripStageControllerProvider);
    if (!_requestedPlan && trip != null && trip.reservationId != 0) {
      _requestedPlan = true;
      Future.microtask(
        () => ref
            .read(tripStageControllerProvider.notifier)
            .refresh(trip.reservationId, mode: _selectedMode),
      );
    }

    return Scaffold(
      backgroundColor: _DepartureColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 112),
              sliver: SliverList.list(
                children: [
                  const _DepartureAppBar(),
                  _LeaveTimeHero(stageState: stageState),
                  const SizedBox(height: 25),
                  _TransportModeSelector(
                    selectedMode: _selectedMode,
                    onSelected: (mode) {
                      setState(() {
                        _selectedMode = mode;
                        _requestedPlan = false;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  _RouteSummaryCard(
                    tripLabel: trip == null
                        ? 'Select a trip'
                        : '${trip.fromCity} to ${trip.toCode}\nTerm 3',
                  ),
                  const SizedBox(height: 21),
                  _TimingCard(stageState: stageState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveTimeHero extends StatelessWidget {
  final AsyncValue<TripStageState> stageState;

  const _LeaveTimeHero({required this.stageState});

  @override
  Widget build(BuildContext context) {
    final leaveAt =
        stageState.valueOrNull?.departurePlan?['leave_at'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _DepartureColors.chip,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'SAFE TO LEAVE',
            style: TextStyle(
              color: _DepartureColors.title,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _formatTime(leaveAt),
          style: const TextStyle(
            color: _DepartureColors.title,
            fontSize: 46,
            fontWeight: FontWeight.w900,
            height: 0.95,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Best time to leave for your flight',
          style: TextStyle(
            color: _DepartureColors.title,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static String _formatTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '--:--';
    final hour = parsed.hour == 0
        ? 12
        : (parsed.hour > 12 ? parsed.hour - 12 : parsed.hour);
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }
}

class _TransportModeSelector extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onSelected;

  const _TransportModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('driving', Icons.directions_car, 'Car'),
      ('transit', Icons.train, 'Train'),
      ('taxi', Icons.local_taxi, 'Taxi'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSPORT MODE',
          style: TextStyle(
            color: _DepartureColors.label,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 43,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _DepartureColors.card,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: modes
                .map(
                  (mode) => Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelected(mode.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selectedMode == mode.$1
                              ? _DepartureColors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              mode.$2,
                              color: selectedMode == mode.$1
                                  ? _DepartureColors.background
                                  : _DepartureColors.title,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              mode.$3,
                              style: TextStyle(
                                color: selectedMode == mode.$1
                                    ? _DepartureColors.background
                                    : _DepartureColors.title,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DepartureAppBar extends StatelessWidget {
  const _DepartureAppBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goNamed('dashboard'),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back,
              color: _DepartureColors.title,
              size: 22,
            ),
          ),
          const SizedBox(width: 2),
          const Expanded(
            child: Text(
              'Plan Departure',
              style: TextStyle(
                color: _DepartureColors.title,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: _DepartureColors.title,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  final String tripLabel;

  const _RouteSummaryCard({required this.tripLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 147,
      padding: const EdgeInsets.fromLTRB(20, 59, 20, 19),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142844), Color(0xFF0A1B31), Color(0xFF07172A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapLinesPainter())),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'ROUTE SUMMARY',
                      style: TextStyle(
                        color: _DepartureColors.label,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      tripLabel,
                      style: const TextStyle(
                        color: _DepartureColors.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 73,
                height: 51,
                decoration: BoxDecoration(
                  color: _DepartureColors.liveCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Live\nTraffic',
                    style: TextStyle(
                      color: _DepartureColors.title,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  final AsyncValue<TripStageState> stageState;

  const _TimingCard({required this.stageState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 51, 26, 28),
      decoration: BoxDecoration(
        color: _DepartureColors.card,
        borderRadius: BorderRadius.circular(23),
      ),
      child: stageState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: _DepartureColors.salmon),
        ),
        data: (state) {
          final plan = state.departurePlan;
          final travelMinutes = plan?['travel_minutes']?.toString() ?? '--';
          final buffer = plan?['check_in_buffer_minutes']?.toString() ?? '--';
          final leaveAt =
              (plan?['leave_at'] as String?)?.substring(11, 16) ?? '--:--';
          return Column(
            children: [
              _TimingRow(
                icon: Icons.access_time,
                label: 'TRAVEL TIME',
                value: '$travelMinutes mins',
                showArrow: true,
              ),
              const SizedBox(height: 26),
              _TimingRow(
                icon: Icons.timer_outlined,
                label: 'SECURITY BUFFER',
                value: '$buffer mins',
              ),
              const SizedBox(height: 30),
              const Divider(color: _DepartureColors.divider, height: 1),
              const SizedBox(height: 21),
              _ArrivalRow(leaveAt: leaveAt),
            ],
          );
        },
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showArrow;

  const _TimingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoftIcon(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _DepartureColors.label,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _DepartureColors.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (showArrow)
          const Icon(
            Icons.arrow_forward,
            color: _DepartureColors.muted,
            size: 17,
          ),
      ],
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _DepartureColors.iconBackground,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: _DepartureColors.title, size: 20),
    );
  }
}

class _ArrivalRow extends StatelessWidget {
  final String leaveAt;

  const _ArrivalRow({required this.leaveAt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EST. ARRIVAL',
                style: TextStyle(
                  color: _DepartureColors.label,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                leaveAt,
                style: const TextStyle(
                  color: _DepartureColors.title,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: _DepartureColors.warningBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.flight_land,
            color: _DepartureColors.salmon,
            size: 19,
          ),
        ),
      ],
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 8; i++) {
      final path = Path()
        ..moveTo(-20, size.height * (0.1 + i * 0.1))
        ..cubicTo(
          size.width * 0.25,
          size.height * (0.05 + i * 0.08),
          size.width * 0.58,
          size.height * (0.17 + i * 0.07),
          size.width + 20,
          size.height * (0.04 + i * 0.1),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DepartureColors {
  _DepartureColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color chip = Color(0xFF22385C);
  static const Color liveCard = Color(0xFF243650);
  static const Color blue = Color(0xFF4A91F8);
  static const Color title = Color(0xFFD5E4FF);
  static const Color label = Color(0xFFAABCE0);
  static const Color muted = Color(0xFF6D7D95);
  static const Color divider = Color(0xFF263A55);
  static const Color iconBackground = Color(0xFF1D2D46);
  static const Color warningBackground = Color(0xFF41213A);
  static const Color salmon = Color(0xFFFFACA6);
  // ignore: unused_field
  static const Color buttonText = Color(0xFF4E1017);
}
