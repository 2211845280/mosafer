import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/google_directions_service.dart';
import '../../../../core/utils/route_geometry.dart';
import 'on_way_map_args.dart';
import 'on_way_theme.dart';

class OnWayRouteMap extends StatefulWidget {
  final OnWayMapArgs args;
  final double? height;
  final BorderRadius borderRadius;
  final bool fitBoundsOnUpdate;
  final GoogleDirectionsService? directionsService;

  const OnWayRouteMap({
    super.key,
    required this.args,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.fitBoundsOnUpdate = true,
    this.directionsService,
  });

  @override
  State<OnWayRouteMap> createState() => _OnWayRouteMapState();
}

class _OnWayRouteMapState extends State<OnWayRouteMap> {
  GoogleMapController? _controller;
  late GoogleDirectionsService _directionsService;

  List<GoogleDirectionsRoute> _routeAlternatives = const [];
  int _selectedRouteIndex = 0;
  List<LatLng> _resolvedRoutePoints = const [];
  bool _isLoadingRoute = false;
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _directionsService = widget.directionsService ?? GoogleDirectionsService();
    _resolvedRoutePoints = _bestAvailablePoints();
    _fetchRoadRoute();
  }

  @override
  void didUpdateWidget(covariant OnWayRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeInputsChanged =
        oldWidget.args.origin != widget.args.origin ||
        oldWidget.args.airport != widget.args.airport ||
        oldWidget.args.routePoints != widget.args.routePoints;

    if (routeInputsChanged) {
      _routeAlternatives = const [];
      _selectedRouteIndex = 0;
      _resolvedRoutePoints = _bestAvailablePoints();
      _fetchRoadRoute();
    } else if (widget.fitBoundsOnUpdate &&
        oldWidget.args.isTracking != widget.args.isTracking) {
      _fitCamera();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller?.dispose();
    }
    super.dispose();
  }

  List<LatLng> _bestAvailablePoints() {
    if (isDetailedRoadRoute(widget.args.routePoints)) {
      return widget.args.routePoints;
    }
    return const [];
  }

  GoogleDirectionsRoute? get _selectedRoute {
    if (_routeAlternatives.isEmpty) {
      return null;
    }
    if (_selectedRouteIndex < 0 ||
        _selectedRouteIndex >= _routeAlternatives.length) {
      return _routeAlternatives.first;
    }
    return _routeAlternatives[_selectedRouteIndex];
  }

  List<GoogleDirectionsRoute> _sortedAlternatives(
    List<GoogleDirectionsRoute> routes,
  ) {
    final sorted = List<GoogleDirectionsRoute>.from(routes)
      ..sort((a, b) {
        final durationCompare = a.durationSeconds.compareTo(b.durationSeconds);
        if (durationCompare != 0) {
          return durationCompare;
        }
        return a.distanceMeters.compareTo(b.distanceMeters);
      });
    return sorted;
  }

  int _indexOfFastestRoute(List<GoogleDirectionsRoute> routes) {
    if (routes.isEmpty) {
      return 0;
    }

    var fastestIndex = 0;
    for (var index = 1; index < routes.length; index++) {
      final candidate = routes[index];
      final fastest = routes[fastestIndex];
      if (candidate.durationSeconds < fastest.durationSeconds ||
          (candidate.durationSeconds == fastest.durationSeconds &&
              candidate.distanceMeters < fastest.distanceMeters)) {
        fastestIndex = index;
      }
    }
    return fastestIndex;
  }

  Future<void> _fetchRoadRoute() async {
    final origin = widget.args.origin;

    if (origin == null) {
      if (!mounted) return;

      setState(() {
        _isLoadingRoute = false;
        _routeAlternatives = const [];
        _selectedRouteIndex = 0;
        _resolvedRoutePoints = const [];
      });

      return;
    }

    final generation = ++_fetchGeneration;

    if (mounted) {
      setState(() {
        _isLoadingRoute = true;
        _routeAlternatives = const [];
        _selectedRouteIndex = 0;
        _resolvedRoutePoints = const [];
      });
    }

    final alternatives = await _directionsService.tryGetRouteAlternatives(
      origin: origin,
      destination: widget.args.airport,
    );

    debugPrint('Route alternatives count: ${alternatives.length}');

    if (!mounted || generation != _fetchGeneration) return;

    setState(() {
      _isLoadingRoute = false;

      if (alternatives.isNotEmpty) {
        _routeAlternatives = alternatives;
        _selectedRouteIndex = _indexOfFastestRoute(alternatives);
        _resolvedRoutePoints = _selectedRoute!.points;
        return;
      }

      if (isDetailedRoadRoute(widget.args.routePoints)) {
        _routeAlternatives = const [];
        _selectedRouteIndex = 0;
        _resolvedRoutePoints = widget.args.routePoints;
        return;
      }

      _routeAlternatives = const [];
      _selectedRouteIndex = 0;
      _resolvedRoutePoints = const [];
    });

    await _fitCamera();
  }

  void _selectRoute(int index) {
    if (index < 0 || index >= _routeAlternatives.length) {
      return;
    }

    setState(() {
      _selectedRouteIndex = index;
      _resolvedRoutePoints = _routeAlternatives[index].points;
    });

    _fitCamera();
  }

  List<LatLng> get _polylinePoints {
    if (isDetailedRoadRoute(_resolvedRoutePoints)) {
      return _resolvedRoutePoints;
    }

    return const [];
  }

  Set<Polyline> _buildPolylines() {
    if (_routeAlternatives.isEmpty) {
      final polylinePoints = _polylinePoints;
      if (polylinePoints.length < 2) {
        return const {};
      }

      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: widget.args.isTracking ? OnWayColors.salmon : OnWayColors.blue,
          width: 5,
          geodesic: false,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
    }

    final activeColor =
        widget.args.isTracking ? OnWayColors.salmon : OnWayColors.blue;
    final mutedColor = activeColor.withValues(alpha: 0.35);
    final polylines = <Polyline>{};

    for (var index = 0; index < _routeAlternatives.length; index++) {
      final route = _routeAlternatives[index];
      if (!isDetailedRoadRoute(route.points)) {
        continue;
      }

      final isSelected = index == _selectedRouteIndex;
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$index'),
          points: route.points,
          color: isSelected ? activeColor : mutedColor,
          width: isSelected ? 5 : 4,
          geodesic: false,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: isSelected ? 2 : 1,
        ),
      );
    }

    return polylines;
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null) return;

    final routePoints = _polylinePoints;
    final points = <LatLng>[
      widget.args.airport,
      ...routePoints,
      if (widget.args.origin != null) widget.args.origin!,
    ];

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 12),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          widget.args.origin ?? widget.args.airport,
          11,
        ),
      );
    }
  }

  String _routeChipLabel(GoogleDirectionsRoute route, int displayIndex) {
    final distance = route.distanceKm.toStringAsFixed(1);
    final summary = route.summary?.trim();
    final summarySuffix = summary == null || summary.isEmpty ? '' : ' · $summary';
    return 'Route $displayIndex · ${route.durationMinutes} min · $distance km$summarySuffix';
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final origin = args.origin;
    final initialTarget = origin ?? args.airport;
    final showRouteSelector = !_isLoadingRoute && _routeAlternatives.length > 1;

    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: origin == null ? 12 : 10,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        _fitCamera();
      },
      myLocationEnabled: args.showLiveLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('airport'),
          position: args.airport,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: args.airportName,
            snippet: args.airportCode,
          ),
        ),
        if (origin != null)
          Marker(
            markerId: const MarkerId('origin'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(title: args.originLabel),
          ),
      },
      polylines: _buildPolylines(),
    );

    Widget content = map;
    if (widget.height != null) {
      content = SizedBox(height: widget.height, child: content);
    }

    content = ClipRRect(borderRadius: widget.borderRadius, child: content);

    final overlays = <Widget>[
      Positioned.fill(child: content),
      if (_isLoadingRoute)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: OnWayColors.background.withValues(alpha: 0.35),
                borderRadius: widget.borderRadius,
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
        ),
      if (showRouteSelector)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _RouteSelector(
            routes: _sortedAlternatives(_routeAlternatives),
            selectedRouteIndex: _selectedRoute?.routeIndex,
            labelBuilder: (route, displayIndex) =>
                _routeChipLabel(route, displayIndex),
            onRouteSelected: (route) {
              final index = _routeAlternatives.indexWhere(
                (candidate) => candidate.routeIndex == route.routeIndex,
              );
              if (index >= 0) {
                _selectRoute(index);
              }
            },
          ),
        ),
      if (args.mapCaption != null)
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: OnWayColors.background.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                args.mapCaption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OnWayColors.title,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
    ];

    if (!_isLoadingRoute && args.mapCaption == null && !showRouteSelector) {
      return content;
    }

    return Stack(children: overlays);
  }
}

class _RouteSelector extends StatelessWidget {
  const _RouteSelector({
    required this.routes,
    required this.selectedRouteIndex,
    required this.labelBuilder,
    required this.onRouteSelected,
  });

  final List<GoogleDirectionsRoute> routes;
  final int? selectedRouteIndex;
  final String Function(GoogleDirectionsRoute route, int displayIndex)
  labelBuilder;
  final ValueChanged<GoogleDirectionsRoute> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OnWayColors.background.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            for (var index = 0; index < routes.length; index++)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == routes.length - 1 ? 0 : 8,
                ),
                child: _RouteChip(
                  label: labelBuilder(routes[index], index + 1),
                  selected: routes[index].routeIndex == selectedRouteIndex,
                  onTap: () => onRouteSelected(routes[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? OnWayColors.blue : OnWayColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? OnWayColors.background : OnWayColors.title,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
