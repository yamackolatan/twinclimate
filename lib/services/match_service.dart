import '../logic/match_engine.dart';
import '../models/matching.dart';
import '../models/weather.dart';
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

  /// Open-Meteo forecasts reach 16 days ahead (today + 15).
  static const _forecastDays = 16;

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
        request.home.latitude, request.home.longitude, request.rangeKm);
    onProgress?.call('Checking ${spots.length} spots around '
        '${request.home.name}…');

    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final lastForecastDay = today.add(const Duration(days: _forecastDays - 1));
    final days = switch (request.mode) {
      MatchMode.specificDate => [
          DateTime(request.date.year, request.date.month, request.date.day),
        ],
      MatchMode.period => [
          for (var i = 0; i < request.periodDays && i < _forecastDays; i++)
            today.add(Duration(days: i)),
        ],
    };
    // Late starts can run past midnight; fetch the next day when possible.
    final nextDay = days.last.add(const Duration(days: 1));
    final lastDay = nextDay.isAfter(lastForecastDay) ? days.last : nextDay;

    final forecasts = <SpotForecast>[];
    for (var i = 0; i < spots.length; i += _batchSize) {
      final batch = spots.skip(i).take(_batchSize).toList();
      forecasts.addAll(await _retry(() => weather.fetchHourlyMany(
            points: [for (final s in batch) (s.latitude, s.longitude)],
            firstDay: days.first,
            lastDay: lastDay,
          )));
    }

    // Spots in the sea (height 0) are left out; the start point stays.
    final land = [
      for (var i = 0; i < spots.length; i++)
        if (spots[i].isHome || forecasts[i].elevationM > 0)
          (spots[i].copyWith(elevationM: forecasts[i].elevationM),
              forecasts[i].hours),
    ];

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
        notBefore: now.add(const Duration(minutes: 15)),
      );
      if (result != null) perSpot.add(result);
    }

    final ranked = rankResults(perSpot);
    return MatchResult(
      target: target,
      results: ranked,
      spotsChecked: land.length,
      notes: adaptationNotes(
        best: ranked.isEmpty ? null : ranked.first,
        target: target.stats,
        sport: request.sport,
        rangeKm: request.rangeKm,
      ),
    );
  }

  Future<T> _retry<T>(Future<T> Function() action) async {
    for (var attempt = 1;; attempt++) {
      try {
        return await action();
      } on WeatherServiceException catch (e) {
        if (!e.retryable || attempt >= 3) rethrow;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
  }
}
