import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/trip.dart';

class DeletedTripEntry {
  final Trip trip;
  final DateTime deletedAt;

  const DeletedTripEntry({required this.trip, required this.deletedAt});

  factory DeletedTripEntry.fromJson(Map<String, dynamic> json) {
    return DeletedTripEntry(
      trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
      deletedAt: DateTime.parse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip': trip.toJson(),
      'deletedAt': deletedAt.toIso8601String(),
    };
  }
}

class DeletedTripsStore {
  static const _storageKey = 'deleted_trips_v1';
  static const retentionDays = 7;

  static bool isExpired(DeletedTripEntry entry) {
    return DateTime.now().isAfter(
      entry.deletedAt.add(const Duration(days: retentionDays)),
    );
  }

  Future<List<DeletedTripEntry>> _readEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => DeletedTripEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _saveEntries(List<DeletedTripEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<DeletedTripEntry>> purgeExpired() async {
    final entries = await _readEntries();
    final active = entries.where((entry) => !isExpired(entry)).toList();
    if (active.length != entries.length) {
      await _saveEntries(active);
    }
    return active;
  }

  Future<List<DeletedTripEntry>> load() async => purgeExpired();

  Future<Set<int>> loadDeletedIds() async {
    final entries = await load();
    return entries.map((entry) => entry.trip.reservationId).toSet();
  }

  Future<void> softDelete(Trip trip) async {
    final entries = await purgeExpired();
    final filtered = entries
        .where((entry) => entry.trip.reservationId != trip.reservationId)
        .toList();
    filtered.insert(
      0,
      DeletedTripEntry(trip: trip, deletedAt: DateTime.now()),
    );
    await _saveEntries(filtered);
  }

  Future<Trip?> restore(int reservationId) async {
    final entries = await purgeExpired();
    DeletedTripEntry? restored;
    final remaining = <DeletedTripEntry>[];

    for (final entry in entries) {
      if (entry.trip.reservationId == reservationId) {
        restored = entry;
      } else {
        remaining.add(entry);
      }
    }

    if (restored == null) {
      return null;
    }

    await _saveEntries(remaining);
    return restored.trip;
  }

  Future<void> permanentDelete(int reservationId) async {
    final entries = await purgeExpired();
    final remaining = entries
        .where((entry) => entry.trip.reservationId != reservationId)
        .toList();
    if (remaining.length == entries.length) {
      return;
    }
    await _saveEntries(remaining);
  }
}
