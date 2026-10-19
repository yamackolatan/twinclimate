import '../logic/fingerprint_builder.dart';
import '../logic/typical_weather.dart';
import '../models/fingerprint.dart';
import '../models/place.dart';
import '../models/weather.dart';
import 'weather_service.dart';

/// Typical weather for one session beyond the forecast.
class TypicalSession {
  const TypicalSession({
    required this.forecast,
    required this.firstYear,
    required this.lastYear,
    required this.feelsSpread,
  });

  /// Hour-by-hour typical conditions, usable like a real forecast.
  final SessionForecast forecast;
  final int firstYear;
  final int lastYear;

  /// Felt temperature over all the hours used ("typically 12–17°").
  final Stat feelsSpread;
}

/// Typical conditions for one race-matching spot: its ground height and a
/// typical hour for every clock hour of the day (and the next day).
class TypicalSpot {
  const TypicalSpot({required this.elevationM, required this.hours});

  final double elevationM;
  final List<HourWeather> hours;
}

/// Builds "typical weather" from the last 10 years of records when a date
/// is past the 16-day forecast (owner request, Oct 2026).
class TypicalWeatherService {
  TypicalWeatherService(
    this.weather, {
    DateTime Function()? clock,
    this.retryDelay = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  final WeatherService weather;
  final DateTime Function() _clock;
  final Duration retryDelay;

  /// Typical conditions for the session hours [slots] (local times).
  Future<TypicalSession> forSession(
    Place place,
    List<DateTime> slots, {
    void Function(int done, int total)? onProgress,
  }) async {
    final date = dayOnly(slots.first);
    final extraDays = dayOnly(slots.last).difference(date).inDays;
    final years = historyYears(
      month: date.month,
      day: date.day,
      extraDays: extraDays,
      today: _clock(),
    );
    if (years.isEmpty) {
      throw WeatherServiceException('No past weather is available yet.');
    }
    var done = 0;
    onProgress?.call(0, years.length);
    final perYear = await Future.wait([
      for (final year in years)
        _retry(
          () => weather.fetchHistory(
            place: place,
            firstDay: DateTime.utc(
              year,
              date.month,
              date.day - fingerprintDaySpread,
            ),
            lastDay: DateTime.utc(
              year,
              date.month,
              date.day + fingerprintDaySpread + extraDays,
            ),
          ),
        ).then((hours) {
          onProgress?.call(++done, years.length);
          return hours;
        }),
    ]);
    final history = [for (final h in perYear) ...h];
    final hours = typicalHours(
      history: history,
      years: years,
      date: date,
      slots: slots,
    );
    if (hours.isEmpty) {
      throw WeatherServiceException(
        'No past weather records were found for this place and date.',
      );
    }
    return TypicalSession(
      forecast: SessionForecast(hours),
      firstYear: years.first,
      lastYear: years.last,
      feelsSpread: typicalFeelsSpread(
        history: history,
        years: years,
        date: date,
        slots: slots,
      ),
    );
  }

  /// Typical conditions on [date] for every spot in [points], as one hour
  /// per clock hour over [date] and the following day (late sessions run
  /// past midnight). One request per year covers all spots; requests run
  /// one after another to stay within the free service's per-minute limit.
  Future<(List<TypicalSpot>, List<int>)> forSpots(
    List<(double, double)> points,
    DateTime date, {
    void Function(int done, int total)? onProgress,
  }) async {
    final key =
        '${dayOnly(date).toIso8601String()}|'
        '${[for (final p in points) '${p.$1.toStringAsFixed(3)},${p.$2.toStringAsFixed(3)}'].join(';')}';
    final cached = _spotCache[key];
    if (cached != null) return cached;
    final result = await _forSpots(points, date, onProgress: onProgress);
    _spotCache[key] = result;
    if (_spotCache.length > 6) _spotCache.remove(_spotCache.keys.first);
    return result;
  }

  /// History is ~6 MB per far-ahead search and counts heavily against the
  /// free service's hourly limit, so results are kept for the visit:
  /// changing sport, weights or training hours doesn't download again.
  static final Map<String, (List<TypicalSpot>, List<int>)> _spotCache = {};

  Future<(List<TypicalSpot>, List<int>)> _forSpots(
    List<(double, double)> points,
    DateTime date, {
    void Function(int done, int total)? onProgress,
  }) async {
    final day = dayOnly(date);
    final years = historyYears(
      month: day.month,
      day: day.day,
      extraDays: 1,
      today: _clock(),
    );
    if (years.isEmpty) {
      throw WeatherServiceException('No past weather is available yet.');
    }
    final histories = [for (final _ in points) <PastHour>[]];
    final elevations = List<double>.filled(points.length, 1);
    onProgress?.call(0, years.length);
    for (var y = 0; y < years.length; y++) {
      final year = years[y];
      final result = await _retry(
        () => weather.fetchHistoryMany(
          points: points,
          firstDay: DateTime.utc(
            year,
            day.month,
            day.day - fingerprintDaySpread,
          ),
          lastDay: DateTime.utc(
            year,
            day.month,
            day.day + fingerprintDaySpread + 1,
          ),
        ),
      );
      for (var i = 0; i < points.length; i++) {
        histories[i].addAll(result[i].hours);
        elevations[i] = result[i].elevationM;
      }
      onProgress?.call(y + 1, years.length);
    }
    final slots = [for (var h = 0; h < 48; h++) day.add(Duration(hours: h))];
    return (
      [
        for (var i = 0; i < points.length; i++)
          TypicalSpot(
            elevationM: elevations[i],
            hours: typicalHours(
              history: histories[i],
              years: years,
              date: day,
              slots: slots,
            ),
          ),
      ],
      years,
    );
  }

  Future<T> _retry<T>(Future<T> Function() action) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await action();
      } on WeatherServiceException catch (e) {
        if (!e.retryable || attempt >= 3) rethrow;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
  }
}
