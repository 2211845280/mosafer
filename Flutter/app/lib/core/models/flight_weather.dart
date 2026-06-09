class FlightWeatherForecast {
  final String condition;
  final double temperatureC;
  final String description;
  final bool severeAlert;

  const FlightWeatherForecast({
    required this.condition,
    required this.temperatureC,
    required this.description,
    this.severeAlert = false,
  });

  factory FlightWeatherForecast.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FlightWeatherForecast(
        condition: 'cloudy',
        temperatureC: 0,
        description: '',
      );
    }
    return FlightWeatherForecast(
      condition: json['condition'] as String? ?? 'cloudy',
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      severeAlert: json['severe_alert'] == true,
    );
  }
}

FlightWeatherForecast? parseFlightWeather(dynamic raw) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }
  return FlightWeatherForecast.fromJson(raw);
}
