import '../../../l10n/app_localizations.dart';

class PackingItem {
  final String key;
  final String title;
  final String note;
  final String titleAr;
  final String titleEn;
  final String noteAr;
  final String noteEn;

  const PackingItem({
    required this.title,
    this.key = '',
    this.note = '',
    this.titleAr = '',
    this.titleEn = '',
    this.noteAr = '',
    this.noteEn = '',
  });

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      noteAr: json['note_ar'] as String? ?? '',
      noteEn: json['note_en'] as String? ?? '',
    );
  }

  String stableKey(String fallback) => key.trim().isEmpty ? fallback : key;

  String titleFor(AppLocalizations l10n) {
    final localized = l10n.localeName.startsWith('ar') ? titleAr : titleEn;
    return localized.trim().isEmpty ? title : localized;
  }

  String noteFor(AppLocalizations l10n) {
    final localized = l10n.localeName.startsWith('ar') ? noteAr : noteEn;
    return localized.trim().isEmpty ? note : localized;
  }
}

enum PackingWeatherCondition {
  clear,
  cloudy,
  rain,
  snow,
  storm;

  static PackingWeatherCondition? fromJson(String? raw) {
    return switch (raw?.toLowerCase()) {
      'clear' => PackingWeatherCondition.clear,
      'cloudy' => PackingWeatherCondition.cloudy,
      'rain' => PackingWeatherCondition.rain,
      'snow' => PackingWeatherCondition.snow,
      'storm' => PackingWeatherCondition.storm,
      _ => null,
    };
  }
}

class PackingWeatherContext {
  final String destinationCity;
  final int tripDurationDays;
  final PackingWeatherCondition condition;
  final double temperatureC;

  const PackingWeatherContext({
    required this.destinationCity,
    required this.tripDurationDays,
    required this.condition,
    required this.temperatureC,
  });

  factory PackingWeatherContext.fromJson(Map<String, dynamic> json) {
    final condition = PackingWeatherCondition.fromJson(
          json['condition'] as String?,
        ) ??
        PackingWeatherCondition.clear;
    return PackingWeatherContext(
      destinationCity: json['destination_city'] as String? ?? '',
      tripDurationDays: (json['trip_duration_days'] as num?)?.toInt() ?? 1,
      condition: condition,
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PackingListResult {
  final List<PackingItem> mustHave;
  final List<PackingItem> recommended;
  final List<PackingItem> optional;
  final PackingWeatherContext? weather;

  const PackingListResult({
    this.mustHave = const [],
    this.recommended = const [],
    this.optional = const [],
    this.weather,
  });

  factory PackingListResult.fromJson(Map<String, dynamic> json) {
    final weatherRaw = json['weather'];
    return PackingListResult(
      mustHave: _parseItems(json['must_have']),
      recommended: _parseItems(json['recommended']),
      optional: _parseItems(json['optional']),
      weather: weatherRaw is Map<String, dynamic>
          ? PackingWeatherContext.fromJson(weatherRaw)
          : null,
    );
  }

  static List<PackingItem> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => PackingItem.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.title.trim().isNotEmpty)
        .toList();
  }

  bool get isEmpty =>
      mustHave.isEmpty && recommended.isEmpty && optional.isEmpty;
}

class TimelineItem {
  final int daysBefore;
  final String title;
  final String description;
  final String category;

  const TimelineItem({
    required this.daysBefore,
    required this.title,
    this.description = '',
    this.category = 'task',
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      daysBefore: (json['days_before'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'task',
    );
  }
}

class TimelineResult {
  final List<TimelineItem> items;

  const TimelineResult({this.items = const []});

  factory TimelineResult.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return const TimelineResult();
    final items = raw
        .whereType<Map>()
        .map((item) => TimelineItem.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.title.trim().isNotEmpty)
        .toList();
    items.sort((a, b) => b.daysBefore.compareTo(a.daysBefore));
    return TimelineResult(items: items);
  }

  Map<int, List<TimelineItem>> groupedByDaysBefore() {
    final grouped = <int, List<TimelineItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.daysBefore, () => []).add(item);
    }
    return grouped;
  }
}
