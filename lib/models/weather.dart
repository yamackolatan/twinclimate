/// One hour of forecast at a specific place. Times are local to the place.
class HourWeather {
  const HourWeather({
    required this.time,
    required this.temperatureC,
    required this.apparentC,
    required this.humidityPercent,
    required this.precipProbabilityPercent,
    required this.precipitationMm,
    required this.windKmh,
    required this.gustKmh,
    required this.weatherCode,
    required this.isDay,
  });

  final DateTime time;
  final double temperatureC;

  /// "Feels like" temperature.
  final double apparentC;

  final double humidityPercent;
  final double precipProbabilityPercent;
  final double precipitationMm;
  final double windKmh;
  final double gustKmh;

  /// WMO weather code (0 = clear ... 99 = thunderstorm with hail).
  final int weatherCode;

  final bool isDay;
}

/// One hour of recorded (past) weather, used for race fingerprints.
///
/// [time] is the place's local wall-clock time stored as a UTC DateTime,
/// so hour arithmetic is never shifted by the viewer's own time zone or
/// daylight-saving changes.
class PastHour {
  const PastHour({
    required this.time,
    required this.temperatureC,
    required this.apparentC,
    required this.humidityPercent,
    required this.precipitationMm,
    required this.windKmh,
    required this.gustKmh,
  });

  final DateTime time;
  final double temperatureC;
  final double apparentC;
  final double humidityPercent;
  final double precipitationMm;
  final double windKmh;
  final double gustKmh;
}

/// The forecast for a session window, plus the aggregates the gear engine
/// and the summary line are built from.
class SessionForecast {
  SessionForecast(this.hours) : assert(hours.isNotEmpty);

  final List<HourWeather> hours;

  HourWeather get atStart => hours.first;

  double get meanApparentC => _mean([for (final h in hours) h.apparentC]);

  double get meanHumidityPercent =>
      _mean([for (final h in hours) h.humidityPercent]);

  double get maxPrecipProbabilityPercent =>
      _max([for (final h in hours) h.precipProbabilityPercent]);

  double get totalPrecipitationMm =>
      [for (final h in hours) h.precipitationMm].reduce((a, b) => a + b);

  double get maxWindKmh => _max([for (final h in hours) h.windKmh]);

  double get maxGustKmh => _max([for (final h in hours) h.gustKmh]);

  /// Most of the window is clear or only lightly cloudy (WMO codes 0-2).
  bool get mostlyClear =>
      hours.where((h) => h.weatherCode <= 2).length * 2 > hours.length;

  /// Most of the window is in daylight.
  bool get mostlyDaylight =>
      hours.where((h) => h.isDay).length * 2 > hours.length;

  /// Rain is likely enough to plan for.
  bool get rainLikely =>
      maxPrecipProbabilityPercent >= 40 || totalPrecipitationMm >= 0.5;

  /// Proper rain, not just a sprinkle.
  bool get heavyRain =>
      totalPrecipitationMm >= 4 ||
      (maxPrecipProbabilityPercent >= 60 && totalPrecipitationMm >= 2);

  bool get windy => maxWindKmh >= 25 || maxGustKmh >= 45;

  bool get veryWindy => maxWindKmh >= 40 || maxGustKmh >= 60;

  bool get humid => meanHumidityPercent >= 75;

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _max(List<double> values) =>
      values.reduce((a, b) => a > b ? a : b);
}
