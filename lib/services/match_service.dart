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

    // Judged on the starting point's clock (it may be in another time zone).
    final now = request.nowAtHome(_clock());
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

    // Days within the 16-day forecast use the forecast; later days use
    // typical weather from the last 10 years (owner request, Oct 2026).
    final forecastDays = [
      for (final d in requested)
        if (!d.isAfter(lastDayOfForecast)) d,
    ];
    final laterDays = [
      for (final d in requested)
        if (d.isAfter(lastDayOfForecast)) d,
    ];

    List<SpotForecast>? forecasts;
    if (forecastDays.isNotEmpty) {
      // Late starts can run past midnight; fetch the next day when possible.
      final nextDay = forecastDays.last.add(const Duration(days: 1));
      final lastDay = nextDay.isAfter(lastDayOfForecast)
          ? forecastDays.last
          : nextDay;
      forecasts = <SpotForecast>[];
      for (var i = 0; i < spots.length; i += _batchSize) {
        final batch = spots.skip(i).take(_batchSize).toList();
        forecasts.addAll(
          await _retry(
            () => weather.fetchHourlyMany(
              points: [for (final s in batch) (s.latitude, s.longitude)],
              firstDay: forecastDays.first,
              lastDay: lastDay,
            ),
          ),
        );
      }
    }

    List<TypicalSpot>? typicalSpots;
    TypicalBasis? basis;
    if (laterDays.isNotEmpty) {
      // Typical weather is taken around one date: the middle of the days
      // beyond the forecast.
      final date = laterDays[laterDays.length ~/ 2];
      final (spotsTypical, years) =
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
      typicalSpots = spotsTypical;
      basis = TypicalBasis(
        date: date,
        firstYear: years.first,
        lastYear: years.last,
        forPeriod: request.mode == MatchMode.period,
        forecastUntil: forecastDays.isEmpty ? null : forecastDays.last,
      );
    }

    onProgress?.call('Comparing every start time with race day…');
    final perSpot = <PlaceResult>[];
    var landCount = 0;
    for (var i = 0; i < spots.length; i++) {
      final elevation = forecasts?[i].elevationM ?? typicalSpots![i].elevationM;
      // Spots in the sea (height 0) are left out; the start point stays.
      if (!spots[i].isHome && elevation <= 0) continue;
      landCount++;
      final spot = spots[i].copyWith(elevationM: elevation);
      PlaceResult? best(
        List<HourWeather> hours,
        List<DateTime> days, {
        TypicalSpot? typical,
      }) => bestForSpot(
        spot: spot,
        byHour: {
          for (final h in hours)
            DateTime(h.time.year, h.time.month, h.time.day, h.time.hour): h,
        },
        days: days,
        durationMinutes: request.durationMinutes,
        target: target.stats,
        weights: request.weights,
        window: request.window,
        notBefore: typical != null
            ? null
            : now.add(const Duration(minutes: 15)),
        rainChance: typical?.wetShare,
        typical: typical != null,
      );
      final fromForecast = forecasts == null
          ? null
          : best(forecasts[i].hours, forecastDays);
      final fromTypical = typicalSpots == null
          ? null
          : best(typicalSpots[i].hours, [
              basis!.date,
            ], typical: typicalSpots[i]);
      // Each place at its best day, whichever kind of weather it's from.
      final pick = fromTypical == null
          ? fromForecast
          : fromForecast == null ||
                fromTypical.best.score > fromForecast.best.score
          ? fromTypical
          : fromForecast;
      if (pick != null) perSpot.add(pick);
    }

    final ranked = rankResults(perSpot);
    return MatchResult(
      target: target,
      results: ranked,
      spotsChecked: landCount,
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
