import 'dart:math' as math;

import '../models/fingerprint.dart';
import '../models/weather.dart';
import 'fingerprint_builder.dart';

/// Open-Meteo forecasts reach 16 days (today + 15). Further ahead, the app
/// shows typical weather from the last 10 years instead (owner request,
/// Oct 2026): day-to-day forecast skill fades after ~10–16 days, and
/// beyond that a date's typical weather is the honest best estimate.
const int forecastDays = 16;

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime lastForecastDay(DateTime now) =>
    dayOnly(now).add(const Duration(days: forecastDays - 1));

/// True when [day] is past the forecast's reach.
bool beyondForecast(DateTime day, DateTime now) =>
    dayOnly(day).isAfter(lastForecastDay(now));

/// First day the real forecast will cover [day].
DateTime forecastAvailableFrom(DateTime day) =>
    dayOnly(day).subtract(const Duration(days: forecastDays - 1));

/// A rainy hour: at least 0.1 mm.
const double _wetHourMm = 0.1;

/// Typical conditions for each of [slots] (local clock hours, on [date] or
/// the days after it), averaged over [years] × [date] ± [spread] days at
/// the same clock hour. [history] times are local wall-clock stored as
/// UTC (see [PastHour]). Slots with no data are left out.
///
/// The rain "probability" is how often that hour was actually rainy;
/// sky and daylight come from recorded cloud cover and sunshine.
List<HourWeather> typicalHours({
  required List<PastHour> history,
  required List<int> years,
  required DateTime date,
  required List<DateTime> slots,
  int spread = fingerprintDaySpread,
}) {
  final byTime = {for (final h in history) h.time: h};
  final result = <HourWeather>[];
  for (final slot in slots) {
    final dayOffset = dayOnly(slot).difference(dayOnly(date)).inDays;
    final readings = <PastHour>[
      for (final year in years)
        for (var d = -spread; d <= spread; d++)
          ?byTime[DateTime.utc(
            year,
            date.month,
            date.day + d + dayOffset,
            slot.hour,
          )],
    ];
    if (readings.isEmpty) continue;
    double mean(double Function(PastHour) f) =>
        readings.map(f).reduce((a, b) => a + b) / readings.length;
    final radiation = [
      for (final r in readings)
        if (r.radiationWm2 != null) r.radiationWm2!,
    ];
    final clouds = [
      for (final r in readings)
        if (r.cloudCoverPercent != null) r.cloudCoverPercent!,
    ];
    final wetShare =
        readings.where((r) => r.precipitationMm >= _wetHourMm).length /
        readings.length;
    final meanRadiation = radiation.isEmpty
        ? 0.0
        : radiation.reduce((a, b) => a + b) / radiation.length;
    final meanCloud = clouds.isEmpty
        ? 50.0
        : clouds.reduce((a, b) => a + b) / clouds.length;
    result.add(
      HourWeather(
        time: slot,
        temperatureC: mean((r) => r.temperatureC),
        apparentC: mean((r) => r.apparentC),
        humidityPercent: mean((r) => r.humidityPercent),
        precipProbabilityPercent: wetShare * 100,
        precipitationMm: mean((r) => r.precipitationMm),
        windKmh: mean((r) => r.windKmh),
        gustKmh: mean((r) => r.gustKmh),
        weatherCode: _typicalCode(wetShare, meanCloud),
        isDay: radiation.isEmpty
            ? slot.hour >= 7 && slot.hour < 19
            : meanRadiation > 10,
        radiationWm2: meanRadiation,
      ),
    );
  }
  return result;
}

/// WMO-style code for the typical sky: rain when it rained in at least
/// half the years, otherwise by average cloud cover.
int _typicalCode(double wetShare, double cloudPercent) {
  if (wetShare >= 0.5) return 61;
  if (cloudPercent < 25) return 0;
  if (cloudPercent < 50) return 1;
  if (cloudPercent < 80) return 2;
  return 3;
}

/// Spread of the felt temperature over all hours used, for the
/// "typically 12–17°" line.
Stat typicalFeelsSpread({
  required List<PastHour> history,
  required List<int> years,
  required DateTime date,
  required List<DateTime> slots,
  int spread = fingerprintDaySpread,
}) {
  final byTime = {for (final h in history) h.time: h};
  final values = <double>[];
  for (final slot in slots) {
    final dayOffset = dayOnly(slot).difference(dayOnly(date)).inDays;
    for (final year in years) {
      for (var d = -spread; d <= spread; d++) {
        final reading =
            byTime[DateTime.utc(
              year,
              date.month,
              date.day + d + dayOffset,
              slot.hour,
            )];
        if (reading != null) values.add(reading.apparentC);
      }
    }
  }
  if (values.isEmpty) return const Stat(0, 0);
  final m = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) /
      values.length;
  return Stat(m, math.sqrt(variance));
}
