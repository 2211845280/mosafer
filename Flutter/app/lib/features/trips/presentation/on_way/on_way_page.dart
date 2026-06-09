import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/google_directions_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/utils/departure_plan_formatters.dart';
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
import 'on_way_theme.dart';

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
  String? _trafficLevel;
  DateTime? _lastRouteRefresh;
  bool _isTracking = false;
  bool _usingManualOrigin = false;
  String? _originLabel;
  FlightWeatherForecast? _originWeather;
  FlightWeatherForecast? _destinationWeather;
  int? _weatherBufferMinutes;
  String? _message;

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
              : (_routeOrigin != null
                    ? l10n.onWayDemoOriginActive
                    : l10n.onWayPressStart));

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
                style: const TextStyle(
                  color: OnWayColors.title,
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
                style: const TextStyle(
                  color: OnWayColors.muted,
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
                  color: OnWayColors.card,
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
                      bottom: 56,
                      child: Row(
                        children: [
                          IconButton.filled(
                            onPressed: _openExternalDirections,
                            style: IconButton.styleFrom(
                              backgroundColor: OnWayColors.card,
                              foregroundColor: OnWayColors.title,
                            ),
                            tooltip: l10n.onWayOpenInMaps,
                            icon: const Icon(Icons.open_in_new, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => _openFullScreenMap(mapArgs),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: OnWayColors.card,
                                  foregroundColor: OnWayColors.title,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.fullscreen, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.onWayOpenInMaps,
                                      style: const TextStyle(
                                        fontSize: 14,
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
              _RouteStatsCard(
                distanceKm: _routeDistanceKm ?? distanceKm,
                etaMinutes: _routeEtaMinutes,
                trafficLevel: _trafficLevel,
                isTracking: _isTracking,
                message: _message,
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
                  cardColor: OnWayColors.card,
                  titleColor: OnWayColors.title,
                  mutedColor: OnWayColors.muted,
                  iconBackground: OnWayColors.iconBackground,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final startButton = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isTracking ? null : _startNavigation,
            icon: const Icon(Icons.navigation),
            label: Text(
              _isTracking
                  ? l10n.onWayTrackingStarted
                  : l10n.onWayStartNavigation,
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return ColoredBox(
        color: OnWayColors.background,
        child: Column(
          children: [
            Expanded(child: scrollContent),
            startButton,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: OnWayColors.background,
      body: SafeArea(bottom: false, child: scrollContent),
      bottomNavigationBar: startButton,
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

    await _refreshRouteFromCoordinates(
      resolved.lat,
      resolved.lng,
      force: true,
    );
  }

  Future<void> _loadInitialRoute() async {
    await ref.read(homeAddressControllerProvider.notifier).ensureLoaded();
    await _reloadOriginAndRoute();
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
    setState(() => _message = l10n.onWayLocationUnavailable);
  }

  Future<void> _startNavigation() async {
    final homeAddress = ref.read(homeAddressControllerProvider);
    if (homeAddress.isUsableManualOrigin) {
      await _reloadOriginAndRoute();
      if (!mounted) return;
      setState(() {
        _isTracking = true;
        _message = AppLocalizations.of(context)!.onWayManualOriginActive;
      });
      return;
    }

    final firstPosition = await _locationService.currentPosition();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (firstPosition == null) {
      setState(() {
        _routeOrigin = demoOriginLatLng;
        _message = l10n.onWayDemoOriginActive;
      });
      await _refreshRouteFromCoordinates(
        demoOriginLatLng.latitude,
        demoOriginLatLng.longitude,
        force: true,
      );
      return;
    }

    setState(() {
      _currentPosition = firstPosition;
      _routeOrigin = LatLng(firstPosition.latitude, firstPosition.longitude);
      _isTracking = true;
      _usingManualOrigin = false;
      _message = l10n.onWayTrackingActive;
    });
    await _refreshRoute(firstPosition, force: true);

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _routeOrigin = LatLng(position.latitude, position.longitude);
            });
            _refreshRoute(position);
          }
        });
  }

  Future<void> _refreshRoute(Position position, {bool force = false}) async {
    await _refreshRouteFromCoordinates(
      position.latitude,
      position.longitude,
      force: force,
    );
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
          _trafficLevel = data['traffic_level'] as String?;
          _originWeather = parseFlightWeather(data['weather']);
          _destinationWeather = parseFlightWeather(data['destination_weather']);
          _weatherBufferMinutes = (data['weather_buffer_minutes'] as num?)?.round();
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
    final subtitle = usingManualOrigin
        ? (originLabel ?? homeAddress.address ?? l10n.onWaySavedAddressReady)
        : l10n.onWayUseCurrentLocationHint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OnWayColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: OnWayColors.iconBackground,
            child: Icon(
              usingManualOrigin ? Icons.home_outlined : Icons.my_location,
              color: OnWayColors.title,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onWayDepartureFrom,
                  style: const TextStyle(
                    color: OnWayColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OnWayColors.title,
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
  final String? trafficLevel;
  final bool isTracking;
  final String? message;

  const _RouteStatsCard({
    required this.distanceKm,
    required this.etaMinutes,
    required this.trafficLevel,
    required this.isTracking,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final computedEta =
        etaMinutes ??
        (distanceKm == null ? null : (distanceKm! / 55 * 60).round());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnWayColors.card,
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
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.traffic,
            label: l10n.onWayTraffic,
            value: trafficLevel == null
                ? '--'
                : trafficLevelLabel(l10n, trafficLevel),
            valueColor: trafficLevel == null
                ? null
                : trafficLevelColor(trafficLevel),
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
            label: l10n.onWayTracking,
            value: isTracking
                ? l10n.onWayTrackingActiveState
                : l10n.onWayTrackingNotStarted,
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnWayColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: OnWayColors.iconBackground,
          child: Icon(icon, color: OnWayColors.title, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: OnWayColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? OnWayColors.title,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
