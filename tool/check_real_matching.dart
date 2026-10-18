// Runs Race Matching with live forecasts using the app's own code: the
// brief's acceptance case (Ironman Kalmar, from Istanbul, 150 km, a
// Saturday) plus the 14-day period mode.
//
//   dart run tool/check_real_matching.dart [yyyy-mm-dd]

import 'dart:convert';
import 'dart:io';

import 'package:twinclimate/logic/fingerprint_text.dart';
import 'package:twinclimate/logic/match_text.dart';
import 'package:twinclimate/models/fingerprint.dart';
import 'package:twinclimate/models/matching.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/services/fingerprint_service.dart';
import 'package:twinclimate/services/match_service.dart';
import 'package:twinclimate/services/weather_service.dart';

import 'sandbox_proxy.dart';

Future<void> main(List<String> args) async {
  useSandboxProxy();
  final weather = OpenMeteoWeatherService();
  final kona = Platform.environment['RACE'] == 'kona';
  var race = kona
      ? Race(
          id: 'kona',
          name: 'Ironman World Championship Kona',
          place: const Place(
            name: 'Kailua-Kona',
            region: 'Hawaii',
            country: 'United States',
            latitude: 19.6400,
            longitude: -155.9969,
          ),
          date: DateTime(2027, 10, 9),
          startHour: 6,
          startMinute: 25,
          legs: triathlonPresets.last.legs,
        )
      : Race(
          id: 'kalmar',
          name: 'Ironman Kalmar',
          place: const Place(
            name: 'Kalmar',
            region: 'Kalmar',
            country: 'Sweden',
            latitude: 56.6634,
            longitude: 16.3568,
          ),
          date: DateTime(2027, 8, 29),
          startHour: 7,
          startMinute: 0,
          legs: triathlonPresets.last.legs,
        );
  // FINGERPRINT_JSON: output of check_real_weather.dart, to reuse a real
  // fingerprint when the history archive's daily limit is reached.
  final cached = Platform.environment['FINGERPRINT_JSON'];
  if (cached != null) {
    final all = jsonDecode(File(cached).readAsStringSync()) as List;
    final entry = all.firstWhere((e) => e['race'] == race.name);
    race = race.withFingerprint(
      RaceFingerprint.fromJson(entry['fingerprint'] as Map<String, dynamic>),
    );
    stdout.writeln(
      'Using cached real fingerprint for '
      '${race.name} (${race.validFingerprint!.firstYear}–${race.validFingerprint!.lastYear}).',
    );
  } else {
    stdout.writeln('Computing Kalmar race-day climate…');
    race = race.withFingerprint(
      await FingerprintService(weather).compute(race),
    );
  }

  final date = args.isEmpty ? _nextSaturday() : DateTime.parse(args.first);
  final home = presetPlaces.first;
  final cases = [
    (Sport.run, 15.0, MatchMode.specificDate),
    (Sport.bike, 90.0, MatchMode.specificDate),
    (Sport.run, 15.0, MatchMode.period),
  ];
  for (final (sport, km, mode) in cases) {
    final request = MatchRequest(
      race: race,
      sport: sport,
      home: (
        name: home.name,
        latitude: home.latitude,
        longitude: home.longitude,
      ),
      distanceKm: km,
      rangeKm: 150,
      mode: mode,
      date: date,
      periodDays: 14,
      weights: MatchWeights.forSport(sport),
    );
    final watch = Stopwatch()..start();
    final result = await MatchService(weather).run(request);
    stdout.writeln(
      '\n=== ${sport.label} ${formatDistance(km)}, '
      '${mode == MatchMode.specificDate ? formatDay(date) : 'next 14 days'}, '
      '150 km from ${home.name} — ${watch.elapsedMilliseconds} ms, '
      '${result.spotsChecked} land spots ===',
    );
    stdout.writeln(
      'Target (${result.target.label}): '
      '${conditionsLine(result.target.stats)}',
    );
    for (var i = 0; i < result.results.length; i++) {
      final r = result.results[i];
      stdout.writeln(
        '${i + 1}. ${spotTitle(r.spot)} '
        '(${r.spot.latitude.toStringAsFixed(3)}, '
        '${r.spot.longitude.toStringAsFixed(3)}, '
        '${r.spot.elevationM?.round()} m) — ${scoreText(r.best.score)}',
      );
      stdout.writeln('   ${bestStartText(r)} | ${windowText(r)}');
      stdout.writeln(
        '   ${comparisonParts(r.best.conditions, result.target.stats).join(' · ')}',
      );
    }
    for (final note in result.notes) {
      stdout.writeln('NOTE: $note');
    }
  }
}

DateTime _nextSaturday() {
  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day + 1);
  while (d.weekday != DateTime.saturday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}
