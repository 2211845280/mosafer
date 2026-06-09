import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/google_directions_service.dart';
import '../../../../l10n/app_localizations.dart';
import 'on_way_map_args.dart';
import 'on_way_route_map.dart';
import 'on_way_theme.dart';

class OnWayGoogleMapPage extends ConsumerWidget {
  final OnWayMapArgs args;

  const OnWayGoogleMapPage({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final title = args.airportName.trim().isNotEmpty
        ? args.airportName
        : l10n.onWaySubtitle(args.airportCode);
    final directionsService = GoogleDirectionsService(
      apiClient: ref.read(apiClientProvider),
    );

    return Scaffold(
      backgroundColor: OnWayColors.background,
      appBar: AppBar(
        backgroundColor: OnWayColors.background,
        foregroundColor: OnWayColors.title,
        title: Text(title),
      ),
      body: OnWayRouteMap(
        args: OnWayMapArgs(
          airportCode: args.airportCode,
          airportName: args.airportName,
          airport: args.airport,
          origin: args.origin,
          routePoints: args.routePoints,
          isTracking: args.isTracking,
          showLiveLocation: args.showLiveLocation,
          originLabel: args.originLabel,
        ),
        directionsService: directionsService,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}

/// Backwards-compatible alias.
typedef OnWayGooglemap = OnWayGoogleMapPage;
