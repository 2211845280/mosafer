import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/error_message_localizer.dart';
import '../../../../core/models/flight_weather.dart';
import '../../../../core/utils/departure_plan_formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/trip.dart';
import '../active_trip_controller.dart';
import '../shared/flight_weather_section.dart';
import '../trip_stage_controller.dart';
import '../../../../core/theme/app_theme_extension.dart';

bool _isTrainFromMitiga(String mode, String? fromCode) {
  return mode == 'transit' && fromCode?.toUpperCase() == 'MJI';
}

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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.watch(activeTripProvider);
    final stageState = ref.watch(tripStageControllerProvider);
    final trainFromMitiga = _isTrainFromMitiga(_selectedMode, trip?.fromCode);

    if (!_requestedPlan &&
        trip != null &&
        trip.reservationId != 0 &&
        !trainFromMitiga) {
      _requestedPlan = true;
      Future.microtask(
        () => ref
            .read(tripStageControllerProvider.notifier)
            .refresh(trip.reservationId, mode: _selectedMode),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 112),
              sliver: SliverList.list(
                children: [
                  _DepartureAppBar(l10n: l10n),
                  _LeaveTimeHero(l10n: l10n, stageState: stageState),
                  const SizedBox(height: 25),
                  _TransportModeSelector(
                    l10n: l10n,
                    selectedMode: _selectedMode,
                    onSelected: (mode) {
                      setState(() {
                        _selectedMode = mode;
                        _requestedPlan = false;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  if (trainFromMitiga)
                    _NoTrainsCard(l10n: l10n)
                  else ...[
                    _TimingCard(l10n: l10n, stageState: stageState, trip: trip),
                    const SizedBox(height: 18),
                    _FlightWeatherCard(l10n: l10n, stageState: stageState, trip: trip),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTrainsCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _NoTrainsCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        children: [
          Icon(
            Icons.train_outlined,
            color: colors.muted.withValues(alpha: 0.7),
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.planDepartureNoTrainsInCountry,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.title,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveTimeHero extends StatelessWidget {
  final AppLocalizations l10n;
  final AsyncValue<TripStageState> stageState;

  const _LeaveTimeHero({required this.l10n, required this.stageState});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final leaveAt =
        stageState.valueOrNull?.departurePlan?['leave_at'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatTime(leaveAt),
          style: TextStyle(
            color: colors.title,
            fontSize: 46,
            fontWeight: FontWeight.w900,
            height: 0.95,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.planDepartureHeroSubtitle,
          style: TextStyle(
            color: colors.title,
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
  final AppLocalizations l10n;
  final String selectedMode;
  final ValueChanged<String> onSelected;

  const _TransportModeSelector({
    required this.l10n,
    required this.selectedMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final modes = [
      ('driving', Icons.directions_car, l10n.planDepartureModeCar),
      ('transit', Icons.train, l10n.planDepartureModeTrain),
      ('taxi', Icons.local_taxi, l10n.planDepartureModeTaxi),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planDepartureTransportMode,
          style: TextStyle(
            color: colors.label,
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
            color: colors.card,
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
                              ? colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              mode.$2,
                              color: selectedMode == mode.$1
                                  ? colors.background
                                  : colors.title,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              mode.$3,
                              style: TextStyle(
                                color: selectedMode == mode.$1
                                    ? colors.background
                                    : colors.title,
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
  final AppLocalizations l10n;

  const _DepartureAppBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 43,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goNamed('dashboard'),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.arrow_back,
              color: colors.title,
              size: 22,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              l10n.planDepartureTitle,
              style: TextStyle(
                color: colors.title,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightWeatherCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AsyncValue<TripStageState> stageState;
  final Trip? trip;

  const _FlightWeatherCard({
    required this.l10n,
    required this.stageState,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return stageState.maybeWhen(
      data: (state) {
        final plan = state.departurePlan;
        if (plan == null) {
          return const SizedBox.shrink();
        }
        return FlightWeatherSection(
          l10n: l10n,
          originWeather: parseFlightWeather(plan['weather']),
          destinationWeather: parseFlightWeather(plan['destination_weather']),
          originLabel: trip?.fromCity ?? trip?.fromCode ?? '--',
          destinationLabel: trip?.toCity ?? trip?.toCode ?? '--',
          weatherBufferMinutes: (plan['weather_buffer_minutes'] as num?)?.round(),
          cardColor: colors.card,
          titleColor: colors.title,
          mutedColor: colors.muted,
          iconBackground: colors.iconBackground,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TimingCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AsyncValue<TripStageState> stageState;
  final Trip? trip;

  const _TimingCard({
    required this.l10n,
    required this.stageState,
    this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 51, 26, 28),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(23),
      ),
      child: stageState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          localizeUserFacingError(error, l10n),
          style: TextStyle(color: colors.salmon),
        ),
        data: (state) {
          final plan = state.departurePlan;
          final travelMinutes = plan?['travel_minutes'];
          final travelMinutesLabel =
              travelMinutes?.toString() ?? '--';
          final distanceKm = (plan?['distance_km'] as num?)?.toDouble();
          final trafficLevel = plan?['traffic_level'] as String?;
          final expectedArrival = formatExpectedArrival(
            plan?['leave_at'] as String?,
            travelMinutes as num?,
          );
          return Column(
            children: [
              _TimingRow(
                icon: Icons.access_time,
                label: l10n.planDepartureTravelTime,
                value: '$travelMinutesLabel ${l10n.planDepartureUnitMinutes}',
              ),
              const SizedBox(height: 26),
              _TimingRow(
                icon: Icons.straighten,
                label: l10n.planDepartureDistance,
                value: formatDistanceKm(l10n, distanceKm),
              ),
              const SizedBox(height: 30),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: 21),
              _ArrivalRow(l10n: l10n, expectedArrival: expectedArrival),
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

  const _TimingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                style: TextStyle(
                  color: colors.label,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: colors.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
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
    final colors = context.colors;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.iconBackground,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: colors.title, size: 20),
    );
  }
}

class _ArrivalRow extends StatelessWidget {
  final AppLocalizations l10n;
  final String expectedArrival;

  const _ArrivalRow({required this.l10n, required this.expectedArrival});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planDepartureEstArrival,
                style: TextStyle(
                  color: colors.label,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                expectedArrival,
                style: TextStyle(
                  color: colors.title,
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
          decoration: BoxDecoration(
            color: colors.warningBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.flight_land,
            color: colors.salmon,
            size: 19,
          ),
        ),
      ],
    );
  }
}
