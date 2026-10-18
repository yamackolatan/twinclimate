import '../logic/match_engine.dart';
import '../logic/typical_weather.dart';
import '../models/matching.dart';
import '../models/weather.dart';
import 'typical_weather_service.dart';
import 'weather_service.dart';

/// Finds where and when, within travel range, training conditions come
/// closest to a race's typical race-day weather (F3).
class MatchService {
  MatchService(
    this.weather, {
    DateTime Function()? clock,
    this.retryDelay = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  final WeatherService weather;
  final DateTime Function() _clock;
  final Duration retryDelay;

  /// Forecasts are requested for this many spots at a time.
  static const _batchSize = 50;

  /// [onProgress] receives short status lines for the loading screen.
  Future<MatchResult> run(
    MatchRequest request, {
    void Function(String status)? onProgress,
  }) async {
    final target = MatchTarget.forRace(request.race, request.sport);
    if (target == null) {
      throw StateError('The race-day climate is not ready yet.');
    }

    final spots = generateSpots(
      request.home.latitude,
      request.home.longitude,
      request.rangeKm,
    );
    onProgress?.call(
      'Checking ${spots.length} spots around '
      '${request.home.name}…',
    );

    final now = _clock();
    final today = dayOnly(now);
    final lastDayOfForecast = lastForecastDay(now);
    final requested = switch (request.mode) {
      MatchMode.specificDate => [dayOnly(request.date)],
      MatchMode.period => [
        for (var i = 0; i < request.periodDays; i++)
          if (_periodDay(request, today, i) case final day
              when !day.isBefore(today))
            day,
      ],
    };
    if (requested.isEmpty) {
      throw WeatherServiceException(
        'Those dates are in the past — pick dates from today on.',
        retryable: false,
      );
    }

    // Past the 16-day forecast, rank places by typical weather instead.
    final useTypical = requested.any((d) => d.isAfter(lastDayOfForecast));
    final List<DateTime> days;
    final List<(Spot, List<HourWeather>)> land;
    TypicalBasis? basis;
    if (useTypical) {
      final date = requested[requested.length ~/ 2];
      days = [date];
      final (typicalSpots, years) =
          await TypicalWeatherService(
            weather,
            clock: _clock,
            retryDelay: retryDelay,
          ).forSpots(
            [for (final s in spots) (s.latitude, s.longitude)],
            date,
            onProgress: (done, total) => onProgress?.call(
              'Beyond the 16-day forecast — looking at 10 years of weather '
              'at ${spots.length} spots ($done of $total years)…',
            ),
          );
      basis = TypicalBasis(
        date: date,
        firstYear: years.first,
        lastYear: years.last,
        forPeriod: request.mode == MatchMode.period,
      );
      land = [
        for (var i = 0; i < spots.length; i++)
          if (spots[i].isHome || typicalSpots[i].elevationM > 0)
            (
              spots[i].copyWith(elevationM: typicalSpots[i].elevationM),
              typicalSpots[i].hours,
            ),
      ];
    } else {
      days = requested;
      // Late starts can run past midnight; fetch the next day when possible.
      final nextDay = days.last.add(const Duration(days: 1));
      final lastDay = nextDay.isAfter(lastDayOfForecast) ? days.last : nextDay;
      final forecasts = <SpotForecast>[];
      for (var i = 0; i < spots.length; i += _batchSize) {
        final batch = spots.skip(i).take(_batchSize).toList();
        forecasts.addAll(
          await _retry(
            () => weather.fetchHourlyMany(
              points: [for (final s in batch) (s.latitude, s.longitude)],
              firstDay: days.first,
              lastDay: lastDay,
            ),
          ),
        );
      }
      // Spots in the sea (height 0) are left out; the start point stays.
      land = [
        for (var i = 0; i < spots.length; i++)
          if (spots[i].isHome || forecasts[i].elevationM > 0)
            (
              spots[i].copyWith(elevationM: forecasts[i].elevationM),
              forecasts[i].hours,
            ),
      ];
    }

    onProgress?.call('Comparing every start time with race day…');
    final perSpot = <PlaceResult>[];
    for (final (spot, hours) in land) {
      final byHour = {
        for (final h in hours)
          DateTime(h.time.year, h.time.month, h.time.day, h.time.hour): h,
      };
      final result = bestForSpot(
        spot: spot,
        byHour: byHour,
        days: days,
        durationMinutes: request.durationMinutes,
        target: target.stats,
        weights: request.weights,
        window: request.window,
        notBefore: useTypical ? null : now.add(const Duration(minutes: 15)),
      );
      if (result != null) perSpot.add(result);
    }

    final ranked = rankResults(perSpot);
    return MatchResult(
      target: target,
      results: ranked,
      spotsChecked: land.length,
      typical: basis,
      notes: ranked.isEmpty
          ? [noTimeFoundNote(request.window, request.durationMinutes)]
          : adaptationNotes(
              best: ranked.first,
              target: target.stats,
              sport: request.sport,
              rangeKm: request.rangeKm,
            ),
    );
  }

  static DateTime _periodDay(MatchRequest r, DateTime today, int i) {
    final start = r.periodStart ?? today;
    return DateTime(start.year, start.month, start.day + i);
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
