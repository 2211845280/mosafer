import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/trip.dart';

final activeTripProvider = StateProvider<Trip?>((ref) => null);
