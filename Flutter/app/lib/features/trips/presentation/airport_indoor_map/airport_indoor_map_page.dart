import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/error_message_localizer.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trips_repository.dart';
import '../../domain/indoor_map.dart';
import '../active_trip_controller.dart';
import 'indoor_geo_overlay.dart';
import 'open_level_up_view.dart';

class AirportIndoorMapPage extends ConsumerStatefulWidget {
  const AirportIndoorMapPage({
    super.key,
    this.gate,
    this.highlightCategory,
    this.initialRouteToGate = false,
  });

  final String? gate;

  /// Amenity category from query param: `coffee` or `food`.
  final String? highlightCategory;

  /// When true, auto-select gate level and enable route overlay after load.
  final bool initialRouteToGate;

  @override
  ConsumerState<AirportIndoorMapPage> createState() =>
      _AirportIndoorMapPageState();
}

class _AirportIndoorMapPageState extends ConsumerState<AirportIndoorMapPage> {
  String? _selectedLevel;
  String? _routeGateLevel;
  bool _routeSimulationEnabled = false;
  bool _didAutoRoute = false;
  bool _didAutoHighlight = false;
  Future<IndoorMapData?>? _mapFuture;
  int? _mapReservationId;

  static const _defaultGate = 'G12';

  final MapsService _mapsService = MapsService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.watch(activeTripProvider);

    if (trip == null || trip.reservationId == 0) {
      return _scaffold(
        l10n: l10n,
        body: Center(
          child: Text(
            l10n.openTripFirstAirportFull,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _MapColors.title),
          ),
        ),
      );
    }

    return _scaffold(
      l10n: l10n,
      body: FutureBuilder<IndoorMapData?>(
        future: _futureForReservation(trip.reservationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingState(message: l10n.indoorMapLoading);
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: localizeUserFacingError(snapshot.error!, l10n),
              retryLabel: l10n.indoorMapRetry,
              backLabel: l10n.indoorMapBack,
              onRetry: () => _retryLoad(trip.reservationId),
              onBack: () => context.pop(),
            );
          }

          final map = snapshot.data;
          if (map == null || !map.supported) {
            return _UnsupportedState(
              message: map?.message ?? l10n.indoorMapUnsupported,
              backLabel: l10n.indoorMapBack,
              onBack: () => context.pop(),
            );
          }

          final activeGate = _activeGate(map);
          final gateLevel =
              map.levelForGate(activeGate) ?? _routeGateLevel ?? '1';
          final level = _selectedLevel ?? map.defaultLevel;

          _maybeAutoRouteToGate(map, activeGate, gateLevel);
          _maybeAutoSelectHighlightLevel(gateLevel);

          final showWrongLevelHint =
              _routeSimulationEnabled &&
              _routeGateLevel != null &&
              level != _routeGateLevel;
          final levelHighlights = map.highlightPois
              .where((poi) => poi.level == level)
              .toList();
          final routeActive =
              _routeSimulationEnabled && level == (_routeGateLevel ?? gateLevel);
          final mapHeight = _mapHeight(context);
          final scrollBottomPadding =
              112 + MediaQuery.viewPaddingOf(context).bottom;

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(bottom: scrollBottomPadding),
                  sliver: SliverList.list(
                    children: [
                      _MapHeaderCard(
                        l10n: l10n,
                        map: map,
                        activeGate: activeGate,
                        gateLevel: gateLevel,
                        onOpenFullMap: () => _openFullMap(map, level),
                      ),
                      const SizedBox(height: 10),
                      _LevelSelector(
                        levels: map.levels,
                        selectedLevel: level,
                        onSelected: (lvl) => setState(() => _selectedLevel = lvl),
                      ),
                      if (showWrongLevelHint) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.indoorMapRouteWrongLevel,
                            style: const TextStyle(
                              color: _MapColors.coral,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: mapHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: ColoredBox(
                              color: _MapColors.background,
                              child: Stack(
                                children: [
                                  OpenLevelUpView(
                                    url: _openLevelUpUrl(map, level),
                                    overlay: IndoorGeoOverlay(
                                      map: map,
                                      routeEnabled: routeActive,
                                      highlightPois: levelHighlights,
                                      highlightCategory: map.highlightCategory,
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: _LevelMapBadge(
                                      l10n: l10n,
                                      level: level,
                                      highlightCategory: map.highlightCategory,
                                      hasHighlights: levelHighlights.isNotEmpty,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (routeActive)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _RouteStepsCard(l10n: l10n, gate: activeGate),
                        ),
                      if (levelHighlights.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _AmenityHighlightCard(
                            l10n: l10n,
                            category: map.highlightCategory,
                            pois: levelHighlights,
                            gate: activeGate,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: FilledButton.icon(
                          onPressed: () {
                            if (_routeSimulationEnabled) {
                              setState(() => _routeSimulationEnabled = false);
                            } else {
                              _goToGate(map, activeGate);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _routeSimulationEnabled
                                ? _MapColors.chip
                                : _MapColors.blue,
                            foregroundColor: _MapColors.title,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            _routeSimulationEnabled
                                ? Icons.close
                                : Icons.navigation,
                          ),
                          label: Text(
                            _routeSimulationEnabled
                                ? l10n.indoorMapHideRoute
                                : l10n.indoorMapGoToGate(activeGate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _scaffold({required AppLocalizations l10n, required Widget body}) {
    return Scaffold(
      backgroundColor: _MapColors.background,
      appBar: AppBar(
        backgroundColor: _MapColors.background,
        foregroundColor: _MapColors.title,
        title: Text(l10n.indoorMapTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: body,
    );
  }

  String _activeGate(IndoorMapData map) {
    return (map.highlightGate ?? widget.gate ?? _defaultGate)
        .trim()
        .toUpperCase();
  }

  static double _mapHeight(BuildContext context) {
    final scaled = MediaQuery.sizeOf(context).height * 0.42;
    return scaled < 380 ? scaled : 380;
  }

  void _maybeAutoRouteToGate(
    IndoorMapData map,
    String activeGate,
    String gateLevel,
  ) {
    if (!widget.initialRouteToGate || _didAutoRoute) {
      return;
    }
    _didAutoRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _goToGate(map, activeGate, gateLevel: gateLevel);
    });
  }

  void _maybeAutoSelectHighlightLevel(String gateLevel) {
    if (widget.highlightCategory == null || _didAutoHighlight) {
      return;
    }
    _didAutoHighlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedLevel = gateLevel);
    });
  }

  void _goToGate(IndoorMapData map, String gate, {String? gateLevel}) {
    final level = gateLevel ?? map.levelForGate(gate) ?? '1';
    setState(() {
      _selectedLevel = level;
      _routeGateLevel = level;
      _routeSimulationEnabled = true;
    });
  }

  void _retryLoad(int reservationId) {
    setState(() {
      _mapReservationId = reservationId;
      _mapFuture = _loadMap(reservationId);
      _didAutoRoute = false;
      _didAutoHighlight = false;
    });
  }

  Future<IndoorMapData?> _loadMap(int reservationId) async {
    final result = await ref
        .read(tripsRepositoryProvider)
        .airportIndoorMap(
          reservationId: reservationId,
          gate: widget.gate,
          highlight: widget.highlightCategory,
        );
    return result.when(
      success: (data) => IndoorMapData.fromJson(data),
      failure: (error) => throw Exception(error),
    );
  }

  Future<IndoorMapData?> _futureForReservation(int reservationId) {
    if (_mapReservationId != reservationId || _mapFuture == null) {
      _mapReservationId = reservationId;
      _mapFuture = _loadMap(reservationId);
    }
    return _mapFuture!;
  }

  String _openLevelUpUrl(IndoorMapData map, String level) {
    final viewport = map.viewport;
    final lat = viewport?.centerLat ?? 41.2622;
    final lng = viewport?.centerLng ?? 28.7425;
    final zoom = viewport?.zoom ?? 17;
    final lvl = level.isNotEmpty ? level : (viewport?.openLevelupLevel ?? '1');
    return 'https://openlevelup.net/?lat=$lat&lon=$lng&z=$zoom&t=0'
        '&lvl=${Uri.encodeComponent(lvl)}&tcd=1';
  }

  Future<void> _openFullMap(IndoorMapData map, String level) async {
    final opened = await _mapsService.openAirportMap(_openLevelUpUrl(map, level));
    if (!mounted || opened) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.unableOpenMaps),
      ),
    );
  }
}

class _MapHeaderCard extends StatelessWidget {
  const _MapHeaderCard({
    required this.l10n,
    required this.map,
    required this.activeGate,
    required this.gateLevel,
    required this.onOpenFullMap,
  });

  final AppLocalizations l10n;
  final IndoorMapData map;
  final String activeGate;
  final String gateLevel;
  final VoidCallback onOpenFullMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _MapColors.chip,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _MapColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      map.airportName,
                      style: const TextStyle(
                        color: _MapColors.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _MapColors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        map.airportIata,
                        style: const TextStyle(
                          color: _MapColors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    color: _MapColors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.indoorMapGateLevel(activeGate, gateLevel),
                    style: const TextStyle(
                      color: _MapColors.title,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                map.message ?? l10n.indoorMapOpenLevelUpSource,
                style: const TextStyle(color: _MapColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onOpenFullMap,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.indoorMapOpenFullMap),
                  style: TextButton.styleFrom(
                    foregroundColor: _MapColors.blue,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelMapBadge extends StatelessWidget {
  const _LevelMapBadge({
    required this.l10n,
    required this.level,
    required this.highlightCategory,
    required this.hasHighlights,
  });

  final AppLocalizations l10n;
  final String level;
  final String? highlightCategory;
  final bool hasHighlights;

  @override
  Widget build(BuildContext context) {
    final label = hasHighlights && highlightCategory != null
        ? l10n.indoorMapHighlightBadge(level, highlightCategory!)
        : l10n.indoorMapLevelBadge(level);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _MapColors.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MapColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _MapColors.title,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.levels,
    required this.selectedLevel,
    required this.onSelected,
  });

  final List<IndoorLevel> levels;
  final String selectedLevel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final lvl = levels[index];
          final selected = lvl.id == selectedLevel;
          return ChoiceChip(
            label: Text(lvl.label),
            selected: selected,
            onSelected: (_) => onSelected(lvl.id),
            selectedColor: _MapColors.blue,
            labelStyle: TextStyle(
              color: selected ? _MapColors.background : _MapColors.title,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            backgroundColor: _MapColors.chip,
          );
        },
      ),
    );
  }
}

class _AmenityHighlightCard extends StatelessWidget {
  const _AmenityHighlightCard({
    required this.l10n,
    required this.category,
    required this.pois,
    required this.gate,
  });

  final AppLocalizations l10n;
  final String? category;
  final List<IndoorPoi> pois;
  final String gate;

  @override
  Widget build(BuildContext context) {
    final title = category == 'coffee'
        ? l10n.indoorMapCoffeeNearGate(gate)
        : l10n.indoorMapFoodNearGate(gate);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _MapColors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MapColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _MapColors.title,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final poi in pois)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      category == 'coffee'
                          ? Icons.local_cafe
                          : Icons.restaurant,
                      color: category == 'coffee'
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFF81C784),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        poi.label,
                        style: const TextStyle(
                          color: _MapColors.title,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

class _RouteStepsCard extends StatelessWidget {
  const _RouteStepsCard({required this.l10n, required this.gate});

  final AppLocalizations l10n;
  final String gate;

  @override
  Widget build(BuildContext context) {
    final steps = [
      l10n.indoorMapRouteStepEntrance,
      l10n.indoorMapRouteStepSecurity,
      l10n.indoorMapRouteStepDutyFree,
      l10n.indoorMapRouteStepConcourse,
      l10n.indoorMapRouteStepArrive(gate),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _MapColors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MapColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation, color: _MapColors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.indoorMapRouteTitle(gate),
                    style: const TextStyle(
                      color: _MapColors.title,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  l10n.indoorMapRouteEta(12),
                  style: const TextStyle(
                    color: _MapColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final step in steps)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _MapColors.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: _MapColors.title,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: _MapColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.backLabel,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final String retryLabel;
  final String backLabel;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _MapColors.coral),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: onBack, child: Text(backLabel)),
                const SizedBox(width: 12),
                FilledButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedState extends StatelessWidget {
  const _UnsupportedState({
    required this.message,
    required this.backLabel,
    required this.onBack,
  });

  final String message;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _MapColors.title),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onBack, child: Text(backLabel)),
          ],
        ),
      ),
    );
  }
}

class _MapColors {
  _MapColors._();

  static const Color background = Color(0xFF061326);
  static const Color chip = Color(0xFF26364F);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF77879E);
  static const Color blue = Color(0xFF4A91F8);
  static const Color coral = Color(0xFFFF8B6E);
  static const Color border = Color(0x334A91F8);
  static const Color overlay = Color(0xE0061326);
}
