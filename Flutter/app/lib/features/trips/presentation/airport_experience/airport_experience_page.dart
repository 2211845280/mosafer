import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/error_message_localizer.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/terminal_display.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';
import '../airport_indoor_map/airport_indoor_map_navigation.dart';
import 'airport_arrival_store.dart';
import '../../../../core/theme/app_theme_extension.dart';

class AirportExperiencePage extends ConsumerStatefulWidget {
  final bool embedded;

  const AirportExperiencePage({super.key, this.embedded = false});

  @override
  ConsumerState<AirportExperiencePage> createState() =>
      _AirportExperiencePageState();
}

class _AirportExperiencePageState extends ConsumerState<AirportExperiencePage> {
  final AirportArrivalStore _arrivalStore = AirportArrivalStore();
  AirportArrivalStep _arrivalStep = AirportArrivalStep.none;
  bool _arrivalLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadArrivalStep();
  }

  Future<void> _loadArrivalStep() async {
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      return;
    }
    final step = await _arrivalStore.loadStep(trip.reservationId);
    if (!mounted) {
      return;
    }
    setState(() {
      _arrivalStep = step;
      _arrivalLoaded = true;
    });
  }

  Future<void> _saveArrivalStep(
    int reservationId,
    AirportArrivalStep step,
  ) async {
    await _arrivalStore.saveStep(reservationId, step);
    if (!mounted) {
      return;
    }
    setState(() => _arrivalStep = step);
  }

  void _showCheckInSheet({
    required int reservationId,
    required String gate,
    required AirportArrivalStep initialStep,
  }) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var currentStep = initialStep.hasStarted
            ? initialStep
            : AirportArrivalStep.arrived;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> advance() async {
              if (currentStep.isComplete) {
                return;
              }
              final next = currentStep.nextStep;
              if (next == null) {
                return;
              }
              await _saveArrivalStep(reservationId, next);
              setSheetState(() => currentStep = next);
            }

            final steps = [
              l10n.airportCheckInStepArrived,
              l10n.airportCheckInStepStarted,
              l10n.airportCheckInStepBoardingPass,
              l10n.airportCheckInStepGoToGate(gate),
            ];

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.airportCheckInTitle,
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.airportCheckInGateLabel(gate),
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < steps.length; i++)
                        _CheckInStepRow(
                          label: steps[i],
                          done:
                              currentStep.index > i + 1 ||
                              (currentStep.isComplete && i == steps.length - 1),
                          active:
                              currentStep.index == i + 1 &&
                              !currentStep.isComplete,
                        ),
                      const SizedBox(height: 18),
                      if (!currentStep.isComplete)
                        ElevatedButton(
                          onPressed: advance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.title,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.airportCheckInNextStep,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            openAirportIndoorMap(
                              context,
                              gate: gate,
                              routeToGate: true,
                            );
                          },
                          icon: const Icon(Icons.navigation),
                          label: Text(l10n.airportOpenGateMap(gate)),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await _saveArrivalStep(
                            reservationId,
                            AirportArrivalStep.none,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(l10n.airportCheckInReset),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trip = ref.watch(activeTripProvider);
    final l10n = AppLocalizations.of(context)!;
    if (trip == null) {
      return _AirportEmptyState(l10n: l10n, embedded: widget.embedded);
    }

    final body = FutureBuilder<_AirportData>(
      future: _loadAirportData(ref, trip.reservationId, trip.fromCode, l10n),
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? _AirportData.fromTripCode(trip.fromCode, l10n);
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    widget.embedded ? 0 : 18,
                    16,
                    190,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _LiveExperienceIntro(
                        l10n: l10n,
                        airportName: data.airportName,
                        terminal: data.terminal,
                        onQrPressed: () => _showBoardingQr(context, ref),
                      ),
                      const SizedBox(height: 25),
                      _GateSummary(
                        l10n: l10n,
                        terminal: data.terminal,
                        gate: data.gate,
                      ),
                      if (_arrivalLoaded && _arrivalStep.hasStarted) ...[
                        const SizedBox(height: 16),
                        _ArrivalStatusCard(
                          l10n: l10n,
                          step: _arrivalStep,
                          gate: data.gate,
                          onTap: () => _showCheckInSheet(
                            reservationId: trip.reservationId,
                            gate: data.gate,
                            initialStep: _arrivalStep,
                          ),
                        ),
                      ],
                      const SizedBox(height: 25),
                      _AirportMapCard(l10n: l10n, gate: data.gate),
                      const SizedBox(height: 26),
                      _ShopSectionHeader(l10n: l10n, gate: data.gate),
                      const SizedBox(height: 13),
                      _ShopCards(
                        l10n: l10n,
                        shops: data.shops,
                        gate: data.gate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 17,
              right: 17,
              bottom: 96,
              child: _FixedAirportActions(
                l10n: l10n,
                gate: data.gate,
                reservationId: trip.reservationId,
                arrivalStep: _arrivalStep,
                onArrived: () async {
                  await _saveArrivalStep(
                    trip.reservationId,
                    AirportArrivalStep.arrived,
                  );
                  if (!context.mounted) return;
                  _showCheckInSheet(
                    reservationId: trip.reservationId,
                    gate: data.gate,
                    initialStep: AirportArrivalStep.arrived,
                  );
                },
                onProceedToGate: () => openAirportIndoorMap(
                  context,
                  gate: data.gate,
                  routeToGate: true,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(color: colors.background, child: body);
    }

    return Scaffold(backgroundColor: colors.background, body: body);
  }

  Future<_AirportData> _loadAirportData(
    WidgetRef ref,
    int reservationId,
    String fromCode,
    AppLocalizations l10n,
  ) async {
    final position = await LocationService().currentPosition();
    if (position == null) {
      return _AirportData.fromTripCode(fromCode, l10n);
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
          _AirportData.fromDashboard(data, fallbackCode: fromCode, l10n: l10n),
      failure: (_) => _AirportData.fromTripCode(fromCode, l10n),
    );
  }

  void _showBoardingQr(BuildContext context, WidgetRef ref) {
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.openTripFirstSnackbar),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        final colors = context.colors;
        final dialogL10n = AppLocalizations.of(context)!;
        return FutureBuilder(
          future: ref.read(tripsRepositoryProvider).getMyTickets(),
          builder: (context, snapshot) {
            String? payload;
            Object? errorMessage;
            var hasTicketsForTrip = false;
            if (snapshot.hasError) {
              errorMessage = snapshot.error;
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
                        localizeUserFacingError(errorMessage!, dialogL10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.title),
                      )
                    : payload == null
                    ? Text(
                        hasTicketsForTrip
                            ? dialogL10n.airportQrInvalidTicket
                            : dialogL10n.airportQrNoTicket,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.title),
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
              backgroundColor: colors.card,
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

  factory _AirportData.fromTripCode(String code, AppLocalizations l10n) {
    return _AirportData(
      airportName: '${code.toUpperCase()} Airport',
      terminal: 'T1',
      gate: l10n.airportGateDash,
      minutesToBoarding: 0,
      walkingMinutes: 12,
      shops: [l10n.airportLoungeFallback, l10n.airportCoffeeFallback],
    );
  }

  factory _AirportData.fromDashboard(
    Map<String, dynamic> json, {
    required String fallbackCode,
    required AppLocalizations l10n,
  }) {
    final airport = json['airport'] as Map<String, dynamic>? ?? const {};
    final flight = json['flight_status'] as Map<String, dynamic>? ?? const {};
    return _AirportData(
      airportName:
          airport['name'] as String? ?? '${fallbackCode.toUpperCase()} Airport',
      terminal: flight['terminal']?.toString() ?? 'T1',
      gate: flight['departure_gate']?.toString() ?? l10n.airportGateDash,
      minutesToBoarding:
          (json['boarding']?['minutes_to_boarding'] as num?)?.toInt() ?? 0,
      walkingMinutes:
          (json['walking_time_to_gate_minutes'] as num?)?.toInt() ?? 12,
      shops:
          (json['nearby_food_shops'] as List?)
              ?.whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toList() ??
          [l10n.airportLoungeFallback, l10n.airportCoffeeFallback],
    );
  }
}

class _AirportEmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final bool embedded;

  const _AirportEmptyState({required this.l10n, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.openTripFirstAirportFull,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.title,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    if (embedded) {
      return ColoredBox(color: colors.background, child: content);
    }

    return Scaffold(backgroundColor: colors.background, body: content);
  }
}

class _LiveExperienceIntro extends StatelessWidget {
  final AppLocalizations l10n;
  final String airportName;
  final String terminal;
  final VoidCallback onQrPressed;

  const _LiveExperienceIntro({
    required this.l10n,
    required this.airportName,
    required this.terminal,
    required this.onQrPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.airportWelcomeLine(airportName, terminal),
                style: TextStyle(
                  color: colors.title,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                  letterSpacing: -0.55,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onQrPressed,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.chip,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.qr_code_2, color: colors.salmon, size: 20),
          ),
        ),
      ],
    );
  }
}

class _GateSummary extends StatelessWidget {
  final AppLocalizations l10n;
  final String terminal;
  final String gate;

  const _GateSummary({
    required this.l10n,
    required this.terminal,
    required this.gate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 91,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.airportTerminalLabel,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatTerminalBadge(terminal),
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 39,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                      ),
                    ),
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
            height: 110,
            padding: const EdgeInsets.fromLTRB(18, 21, 18, 18),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.airportAssignedGate,
                  style: TextStyle(
                    color: colors.buttonText,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  gate,
                  style: TextStyle(
                    color: colors.buttonText,
                    fontSize: 49,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AirportMapCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String gate;

  const _AirportMapCard({required this.l10n, required this.gate});

  void _openIndoorMap(BuildContext context) {
    openAirportIndoorMap(context, gate: gate, routeToGate: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openIndoorMap(context),
      child: Container(
        height: 195,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.mapBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(painter: _MapGridPainter(colors)),
              ),
            ),
            Positioned(
              left: 61,
              top: 39,
              child: _MapPin(label: l10n.airportYouPin, color: colors.salmon),
            ),
            Positioned(
              right: 70,
              top: 80,
              child: _MapPin(label: gate.toUpperCase(), color: colors.primary),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: _MapActionButton(
                icon: Icons.open_in_full,
                label: l10n.airportExpandMap,
                onTap: () => _openIndoorMap(context),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: _RoundMapButton(onTap: () => _openIndoorMap(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter(this.colors);

  final AppThemeExtension colors;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = colors.mapHall
      ..style = PaintingStyle.fill;
    for (var y = 12.0; y < size.height; y += 16) {
      for (var x = 12.0; x < size.width; x += 19) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    final pathPaint = Paint()
      ..color = colors.mapCorridor
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
    final colors = context.colors;
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
    final colors = context.colors;
    return SizedBox(
      width: 132,
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.chip,
          foregroundColor: colors.title,
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
          style: TextStyle(
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
    final colors = context.colors;
    return IconButton.filled(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: colors.chip,
        foregroundColor: colors.title,
        fixedSize: const Size(34, 34),
      ),
      icon: const Icon(Icons.layers_outlined, size: 17),
    );
  }
}

class _ShopSectionHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final String gate;

  const _ShopSectionHeader({required this.l10n, required this.gate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      l10n.airportShopsNear(gate),
      style: TextStyle(
        color: colors.title,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ShopCards extends StatelessWidget {
  final AppLocalizations l10n;
  final List<String> shops;
  final String gate;

  const _ShopCards({
    required this.l10n,
    required this.shops,
    required this.gate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final first = shops.isNotEmpty ? shops.first : l10n.airportCoffeeFallback;
    final second = shops.length > 1 ? shops[1] : l10n.airportLoungeFallback;
    final firstHighlight = amenityHighlightForShopTitle(first) ?? 'coffee';
    final secondHighlight = amenityHighlightForShopTitle(second) ?? 'food';

    return Row(
      children: [
        Expanded(
          child: _ShopCard(
            title: first,
            subtitle: l10n.airportNearGate,
            backgroundAsset: 'assets/images/airport/coffee.jpg',
            onTap: () => openAirportIndoorMap(
              context,
              gate: gate,
              highlight: firstHighlight,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: _ShopCard(
            title: second,
            subtitle: l10n.airportNearGate,
            backgroundAsset: 'assets/images/airport/restaurant.jpeg',
            onTap: () => openAirportIndoorMap(
              context,
              gate: gate,
              highlight: secondHighlight,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? backgroundAsset;
  final VoidCallback onTap;

  const _ShopCard({
    required this.title,
    required this.subtitle,
    this.backgroundAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: backgroundAsset != null
              ? DecorationImage(
                  image: AssetImage(backgroundAsset!),
                  fit: BoxFit.cover,
                )
              : null,
          color: backgroundAsset == null ? colors.card : null,
        ),
        child: Stack(
          children: [
            if (backgroundAsset != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
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
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.title,
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
  final AppLocalizations l10n;
  final String gate;
  final int reservationId;
  final AirportArrivalStep arrivalStep;
  final VoidCallback onArrived;
  final VoidCallback onProceedToGate;

  const _FixedAirportActions({
    required this.l10n,
    required this.gate,
    required this.reservationId,
    required this.arrivalStep,
    required this.onArrived,
    required this.onProceedToGate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!arrivalStep.hasStarted)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onArrived,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.title,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                l10n.airportArrivedAtAirport,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        if (!arrivalStep.hasStarted) const SizedBox(height: 10),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onProceedToGate,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.salmon,
              foregroundColor: colors.buttonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(
              l10n.airportProceedToGate(gate),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrivalStatusCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AirportArrivalStep step;
  final String gate;
  final VoidCallback onTap;

  const _ArrivalStatusCard({
    required this.l10n,
    required this.step,
    required this.gate,
    required this.onTap,
  });

  String _statusLabel() {
    return switch (step) {
      AirportArrivalStep.arrived => l10n.airportCheckInStepArrived,
      AirportArrivalStep.checkInStarted => l10n.airportCheckInStepStarted,
      AirportArrivalStep.boardingPassReady =>
        l10n.airportCheckInStepBoardingPass,
      AirportArrivalStep.goToGate => l10n.airportCheckInStepGoToGate(gate),
      AirportArrivalStep.none => l10n.airportArrivedAtAirport,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.chip,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.flight_land, color: colors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.airportArrivalStatusTitle,
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _CheckInStepRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _CheckInStepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = done
        ? colors.primary
        : active
        ? colors.salmon
        : colors.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : active
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done || active ? colors.title : colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
