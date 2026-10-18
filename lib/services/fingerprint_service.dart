import '../logic/fingerprint_builder.dart';
import '../models/fingerprint.dart';
import '../models/race.dart';
import '../models/weather.dart';
import 'weather_service.dart';

/// Downloads a race's 10-year history and turns it into a fingerprint.
class FingerprintService {
  FingerprintService(
    this.weather, {
    DateTime Function()? clock,
    this.attempts = 3,
    this.retryDelay = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  final WeatherService weather;
  final int attempts;
  final Duration retryDelay;
  final DateTime Function() _clock;

  /// [onProgress] is called with (years done, years total) as downloads
  /// finish. One request per year keeps each download small.
  Future<RaceFingerprint> compute(
    Race race, {
    void Function(int done, int total)? onProgress,
  }) async {
    final now = _clock();
    final years = fingerprintYears(race, now);
    if (years.isEmpty) {
      throw FingerprintException('No past years are available yet.');
    }
    var done = 0;
    onProgress?.call(0, years.length);
    final perYear = await Future.wait([
      for (final year in years)
        _fetchYear(race, year).then((hours) {
          onProgress?.call(++done, years.length);
          return hours;
        }),
    ]);
    return buildFingerprint(
      race: race,
      hours: [for (final hours in perYear) ...hours],
      years: years,
      computedAt: now,
    );
  }

  /// Up to [attempts] tries per year: on weak connections an occasional
  /// request stalls, and one failed year would otherwise sink the result.
  Future<List<PastHour>> _fetchYear(Race race, int year) async {
    final (first, last) = historyRange(race, year);
    for (var attempt = 1; ; attempt++) {
      try {
        return await weather.fetchHistory(
          place: race.place,
          firstDay: first,
          lastDay: last,
        );
      } on WeatherServiceException catch (e) {
        if (!e.retryable || attempt >= attempts) rethrow;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
  }
}
