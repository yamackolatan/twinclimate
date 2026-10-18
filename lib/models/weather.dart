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
    this.radiationWm2 = 0,
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

  /// Sunshine strength (global horizontal radiation), W/m². The service's
  /// "feels like" leaves the sun out, so the kit rules add it themselves.
  final double radiationWm2;
}

/// Forecast for one coordinate of a multi-spot request, with the ground
/// height the weather service used (0 over the sea).
class SpotForecast {
  const SpotForecast({required this.elevationM, required this.hours});

  final double elevationM;
  final List<HourWeather> hours;
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
    this.cloudCoverPercent,
    this.radiationWm2,
  });

  final DateTime time;
  final double temperatureC;
  final double apparentC;
  final double humidityPercent;
  final double precipitationMm;
  final double windKmh;
  final double gustKmh;

  /// Optional extras, used for "typical weather" beyond the forecast.
  final double? cloudCoverPercent;
  final double? radiationWm2;
}

/// Recorded history for one coordinate of a multi-spot request, with the
/// ground height the weather service used (0 over the sea).
class SpotHistory {
  const SpotHistory({required this.elevationM, required this.hours});

  final double elevationM;
  final List<PastHour> hours;
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

  double get meanRadiationWm2 => _mean([for (final h in hours) h.radiationWm2]);

  /// Degrees added for sunshine while exercising. The forecast's "feels
  /// like" ignores the sun (checked against the formula), yet studies show
  /// sun raises how warm exercise feels. Conservative estimate: +3 °C in
  /// strong sun (≥ 500 W/m², roughly clear midday), +1.5 °C in moderate
  /// sun (≥ 250 W/m²).
  double get sunBonusC {
    final r = meanRadiationWm2;
    if (r >= 500) return 3;
    if (r >= 250) return 1.5;
    return 0;
  }

  /// Getting wet is treated as 3 °C colder (about one kit range): wet
  /// clothing loses heat much faster, and cycling guides say to go one
  /// level warmer in the wet.
  double get wetPenaltyC =>
      (totalPrecipitationMm >= 0.5 || maxPrecipProbabilityPercent >= 60)
      ? 3
      : 0;

  /// Felt temperature used to choose kit: "feels like" plus sun, minus wet.
  double get kitFeelsC => meanApparentC + sunBonusC - wetPenaltyC;

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _max(List<double> values) =>
      values.reduce((a, b) => a > b ? a : b);
}
