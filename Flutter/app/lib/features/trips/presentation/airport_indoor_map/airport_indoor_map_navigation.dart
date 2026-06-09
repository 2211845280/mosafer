import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void openAirportIndoorMap(
  BuildContext context, {
  String? gate,
  String? highlight,
  bool routeToGate = false,
}) {
  final params = <String, String>{};
  final normalizedGate = gate?.trim();
  if (normalizedGate != null &&
      normalizedGate.isNotEmpty &&
      !normalizedGate.contains('--')) {
    params['gate'] = normalizedGate.toUpperCase();
  }
  if (highlight != null && highlight.isNotEmpty) {
    params['highlight'] = highlight;
  }
  if (routeToGate) {
    params['route'] = 'gate';
  }
  context.pushNamed('airportIndoorMap', queryParameters: params);
}

String? amenityHighlightForShopTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('coffee') || lower.contains('cafe')) {
    return 'coffee';
  }
  if (lower.contains('bite') ||
      lower.contains('food') ||
      lower.contains('snack') ||
      lower.contains('grill')) {
    return 'food';
  }
  return null;
}
