import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/debug/screenshot_mode.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/google_directions_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/models/flight_weather.dart';
import '../../../../core/models/home_address.dart';
import '../../../../core/services/home_address_controller.dart';
import '../../../../core/utils/trip_origin_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';
import '../shared/flight_weather_section.dart';
import 'on_way_address_sheet.dart';
import 'on_way_airport_lookup.dart';
import 'on_way_googleMap.dart';
import 'on_way_map_args.dart';
import 'on_way_route_map.dart';
import '../../../../core/theme/app_theme_extension.dart';

class OnWayPage extends ConsumerStatefulWidget {
  final bool embedded;

  const OnWayPage({super.key, this.embedded = false});

  @override
  ConsumerState<OnWayPage> createState() => _OnWayPageState();
}

class _OnWayPageState extends ConsumerState<OnWayPage> {
  final LocationService _locationService = LocationService();
  final MapsService _mapsService = MapsService();
  GoogleDirectionsService? _directionsService;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  LatLng? _routeOrigin;
  List<LatLng> _routePoints = const [];
  AirportPoint? _routeAirport;
  double? _routeDistanceKm;
  int? _routeEtaMinutes;
  DateTime? _lastRouteRefresh;
  bool _isTracking = false;
  bool _usingManualOrigin = false;
  String? _originLabel;
  FlightWeatherForecast? _originWeather;
  FlightWeatherForecast? _destinationWeather;
  int? _weatherBufferMinutes;

  @override
  void initState() {
    super.initState();
    _directionsService = GoogleDirectionsService(
      apiClient: ref.read(apiClientProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialRoute());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  OnWayMapArgs _mapArgs(AppLocalizations l10n, AirportPoint mapAirport) {
    final homeAddress = ref.read(homeAddressControllerProvider);
    final originLabel = _usingManualOrigin
        ? (_originLabel ?? homeAddress.address ?? l10n.onWaySavedAddressReady)
        : (_currentPosition != null ? l10n.onWayYou : l10n.onWayDemoOriginName);
    final mapCaption = _usingManualOrigin
        ? l10n.onWayManualOriginActive
        : (_currentPosition != null
              ? l10n.onWayLiveConnected
              : (_routeOrigin != null ? null : l10n.onWayPressStart));

    return OnWayMapArgs.fromPageState(
      fromCode: ref.read(activeTripProvider)?.fromCode,
      fromCity: ref.read(activeTripProvider)?.fromCity ?? mapAirport.code,
      mapAirport: mapAirport,
      currentPosition: _usingManualOrigin ? null : _currentPosition,
      routeOrigin: _routeOrigin,
      routePoints: _routePoints,
      isTracking: _isTracking && !_usingManualOrigin,
      originLabel: originLabel,
      mapCaption: mapCaption,
    );
  }

  void _openFullScreenMap(OnWayMapArgs args) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OnWayGoogleMapPage(args: args)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.watch(activeTripProvider);
    final homeAddress = ref.watch(homeAddressControllerProvider);
    final airport = airportFor(trip?.fromCode);
    final mapAirport = _routeAirport ?? airport;
    final mapArgs = _mapArgs(l10n, mapAirport);
    final distanceKm = _currentPosition == null
        ? null
        : distanceKmBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            mapAirport.lat,
            mapAirport.lng,
          );

    final scrollContent = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 0 : 18, 16, 124),
          sliver: SliverList.list(
            children: [
              Text(
                l10n.onWayTitle,
                style: TextStyle(
                  color: colors.title,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _usingManualOrigin
                    ? l10n.onWayManualSubtitle(airport.code)
                    : (_currentPosition == null && _routeOrigin != null
                          ? l10n.onWayDemoSubtitle(airport.code)
                          : l10n.onWaySubtitle(airport.code)),
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _DepartureOriginCard(
                l10n: l10n,
                homeAddress: homeAddress,
                usingManualOrigin: _usingManualOrigin,
                originLabel: _originLabel,
                onEdit: () => showOnWayAddressSheet(
                  context,
                  ref,
                  onSaved: _reloadOriginAndRoute,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 330,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OnWayRouteMap(
                        args: OnWayMapArgs(
                          airportCode: mapArgs.airportCode,
                          airportName: mapArgs.airportName,
                          airport: mapArgs.airport,
                          origin: mapArgs.origin,
                          routePoints: mapArgs.routePoints,
                          isTracking: mapArgs.isTracking,
                          showLiveLocation: mapArgs.showLiveLocation,
                          originLabel: mapArgs.originLabel,
                          mapCaption: mapArgs.mapCaption,
                        ),
                        directionsService: _directionsService,
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _openExternalDirections,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.card,
                                  foregroundColor: colors.title,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.open_in_new, size: 18),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        l10n.onWayOpenInMaps,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => _openFullScreenMap(mapArgs),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.fullscreen, size: 18),
                                    const SizedBox(width: 2),
                                    Text(
                                      l10n.onWayExpandMap,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              //here
              _RouteStatsCard(
                distanceKm: _routeDistanceKm ?? distanceKm,
                etaMinutes: _routeEtaMinutes,
              ),
              if (_originWeather != null || _destinationWeather != null) ...[
                const SizedBox(height: 18),
                FlightWeatherSection(
                  l10n: l10n,
                  originWeather: _originWeather,
                  destinationWeather: _destinationWeather,
                  originLabel: trip?.fromCity ?? mapAirport.code,
                  destinationLabel: trip?.toCity ?? trip?.toCode ?? '--',
                  weatherBufferMinutes: _weatherBufferMinutes,
                  cardColor: colors.card,
                  titleColor: colors.title,
                  mutedColor: colors.muted,
                  iconBackground: colors.iconBackground,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    // final startButton = SafeArea(
    //   top: false,
    //   child: Padding(
    //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    //     child: SizedBox(
    //       height: 54,
    //       child: ElevatedButton.icon(
    //         onPressed: () => _openFullScreenMap(mapArgs),
    //         // icon: const Icon(Icons.fullscreen),
    //         label: Text(l10n.onWayExpandMap),
    //       ),
    //     ),
    //   ),
    // );

    if (widget.embedded) {
      return ColoredBox(
        color: colors.background,
        child: Column(children: [Expanded(child: scrollContent)]),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(bottom: false, child: scrollContent),
    );
  }

  Future<void> _reloadOriginAndRoute() async {
    final homeAddress = ref.read(homeAddressControllerProvider);
    final position = homeAddress.isUsableManualOrigin
        ? null
        : await _locationService.currentPosition();
    if (!mounted) return;

    final resolved = TripOriginResolver.resolve(
      homeAddress: homeAddress,
      gpsPosition: position,
    );

    setState(() {
      _usingManualOrigin = resolved.isManual;
      _originLabel = resolved.label;
      _currentPosition = resolved.isManual ? null : position;
      _routeOrigin = LatLng(resolved.lat, resolved.lng);
      if (resolved.isManual) {
        _isTracking = false;
        _positionSubscription?.cancel();
        _positionSubscription = null;
      }
    });

    await _refreshRouteFromCoordinates(resolved.lat, resolved.lng, force: true);
  }

  Future<void> _loadInitialRoute() async {
    if (kScreenshotMode) {
      await _applyScreenshotDemoRoute();
      return;
    }
    await ref.read(homeAddressControllerProvider.notifier).ensureLoaded();
    await _reloadOriginAndRoute();
  }

  Future<void> _applyScreenshotDemoRoute() async {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentPosition = Position(
        latitude: 32.8872,
        longitude: 13.1913,
        timestamp: now,
        accuracy: 8,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _routeOrigin = const LatLng(32.8872, 13.1913);
      _routeAirport = const AirportPoint('MJI', 32.8941, 13.2760);
      _routeDistanceKm = 9.0;
      _routeEtaMinutes = 10;
      _routePoints = const [
        LatLng(32.8872, 13.1913),
        LatLng(32.8905, 13.2340),
        LatLng(32.8941, 13.2760),
      ];
      _usingManualOrigin = false;
      _isTracking = false;
      _lastRouteRefresh = now;
    });
  }

  Future<void> _openExternalDirections() async {
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.read(activeTripProvider);
    final airport = _routeAirport ?? airportFor(trip?.fromCode);
    final origin = _currentPosition == null ? _routeOrigin : null;
    final opened = await _mapsService.openDirectionsToCoordinates(
      destinationLat: airport.lat,
      destinationLng: airport.lng,
      originLat: _currentPosition?.latitude ?? origin?.latitude,
      originLng: _currentPosition?.longitude ?? origin?.longitude,
    );
    if (!mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.onWayLocationUnavailable)));
  }

  Future<void> _refreshRouteFromCoordinates(
    double lat,
    double lng, {
    bool force = false,
  }) async {
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) return;
    final now = DateTime.now();
    if (!force &&
        _lastRouteRefresh != null &&
        now.difference(_lastRouteRefresh!) < const Duration(seconds: 90)) {
      return;
    }
    _lastRouteRefresh = now;

    final result = await ref
        .read(tripsRepositoryProvider)
        .getDeparturePlan(
          reservationId: trip.reservationId,
          lat: lat,
          lng: lng,
          mode: 'driving',
        );

    result.when(
      success: (data) {
        final encoded = data['encoded_polyline'] as String?;
        final points = encoded == null
            ? const <LatLng>[]
            : (_directionsService?.decodePolyline(encoded) ?? const <LatLng>[]);
        final airportLat = (data['airport_lat'] as num?)?.toDouble();
        final airportLng = (data['airport_lng'] as num?)?.toDouble();
        final originLat = (data['origin_lat'] as num?)?.toDouble() ?? lat;
        final originLng = (data['origin_lng'] as num?)?.toDouble() ?? lng;
        if (!mounted) return;
        setState(() {
          _routePoints = points;
          _routeOrigin = LatLng(originLat, originLng);
          _routeDistanceKm = (data['distance_km'] as num?)?.toDouble();
          _routeEtaMinutes = (data['travel_minutes'] as num?)?.round();
          _originWeather = parseFlightWeather(data['weather']);
          _destinationWeather = parseFlightWeather(data['destination_weather']);
          _weatherBufferMinutes = (data['weather_buffer_minutes'] as num?)
              ?.round();
          if (airportLat != null && airportLng != null) {
            _routeAirport = AirportPoint(trip.fromCode, airportLat, airportLng);
          }
        });
      },
      failure: (_) {
        // Keep live location usable even if the server-side route refresh fails.
      },
    );
  }
}

double distanceKmBetween(double lat1, double lon1, double lat2, double lon2) =>
    distanceKm(lat1, lon1, lat2, lon2);

class _DepartureOriginCard extends StatelessWidget {
  final AppLocalizations l10n;
  final HomeAddress homeAddress;
  final bool usingManualOrigin;
  final String? originLabel;
  final VoidCallback onEdit;

  const _DepartureOriginCard({
    required this.l10n,
    required this.homeAddress,
    required this.usingManualOrigin,
    required this.originLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = usingManualOrigin
        ? (originLabel ?? homeAddress.address ?? l10n.onWaySavedAddressReady)
        : l10n.onWayUseCurrentLocationHint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.iconBackground,
            child: Icon(
              usingManualOrigin ? Icons.home_outlined : Icons.my_location,
              color: colors.title,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onWayDepartureFrom,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: Text(l10n.onWayChangeAddress)),
        ],
      ),
    );
  }
}

class _RouteStatsCard extends StatelessWidget {
  final double? distanceKm;
  final int? etaMinutes;

  const _RouteStatsCard({required this.distanceKm, required this.etaMinutes});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final computedEta =
        etaMinutes ??
        (distanceKm == null ? null : (distanceKm! / 55 * 60).round());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _StatRow(
            icon: Icons.route,
            label: l10n.onWayDistance,
            value: distanceKm == null
                ? '-- km'
                : '${distanceKm!.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.timer_outlined,
            label: l10n.onWayEta,
            value: computedEta == null
                ? '--'
                : '$computedEta ${l10n.planDepartureUnitMinutes}',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colors.iconBackground,
          child: Icon(icon, color: colors.title, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.title,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
