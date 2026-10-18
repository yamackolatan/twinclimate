// Checks "typical weather" beyond the forecast with real history: one
// Quick Session far ahead, and Race Matching (Kalmar run leg) from
// Istanbul for a date months away.
//
//   FINGERPRINT_JSON=real.json dart run tool/check_typical.dart

import 'dart:convert';
import 'dart:io';

import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/logic/match_text.dart';
import 'package:twinclimate/models/fingerprint.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/matching.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/services/match_service.dart';
import 'package:twinclimate/services/typical_weather_service.dart';
import 'package:twinclimate/services/weather_service.dart';

import 'sandbox_proxy.dart';

Future<void> main() async {
  useSandboxProxy();
  final weather = OpenMeteoWeatherService();
  final home = presetPlaces.first;

  // 1. Quick Session, 15 km run on 20 March next year at 08:00.
  final now = DateTime.now();
  final start = DateTime(now.year + 1, 3, 20, 8);
  final plan = SessionPlan(
      sport: Sport.run, place: home, start: start, distanceKm: 15);
  var watch = Stopwatch()..start();
  final typical =
      await TypicalWeatherService(weather).forSession(home, plan.windowHours);
  stdout.writeln('== Quick Session ${formatDay(start)} 08:00, ${home.name} '
      '(${watch.elapsedMilliseconds} ms, ${typical.firstYear}-${typical.lastYear})');
  for (final h in typical.forecast.hours) {
    stdout.writeln('  ${formatTime(h.time)}: ${h.temperatureC.toStringAsFixed(1)}° '
        'feels ${h.apparentC.toStringAsFixed(1)}°, rain ${h.precipProbabilityPercent.round()}%, '
        'wind ${h.windKmh.round()}, sun ${h.radiationWm2.round()} W/m², code ${h.weatherCode}');
  }
  stdout.writeln('  usually feels ${typical.feelsSpread.low.round()}–'
      '${typical.feelsSpread.high.round()}°');
  final kit = mainSuggestions(buildKit(Sport.run, typical.forecast, distanceKm: 15));
  stdout.writeln('  kit: ${[for (final p in BodyPart.values) '${p.label}: ${kit[p] ?? '-'}'].join(' | ')}');

  // 2. Race Matching far ahead (needs a cached real Kalmar fingerprint).
  final cached = Platform.environment['FINGERPRINT_JSON'];
  if (cached == null) return;
  var race = Race(
    id: 'kalmar',
    name: 'Ironman Kalmar',
    place: const Place(name: 'Kalmar', region: 'Kalmar', country: 'Sweden',
        latitude: 56.6634, longitude: 16.3568),
    date: DateTime(2027, 8, 29),
    startHour: 7,
    startMinute: 0,
    legs: triathlonPresets.last.legs,
  );
  final all = jsonDecode(File(cached).readAsStringSync()) as List;
  race = race.withFingerprint(RaceFingerprint.fromJson(
      all.firstWhere((e) => e['race'] == race.name)['fingerprint']
          as Map<String, dynamic>));
  final date = DateTime(now.year + 1, 6, 20);
  watch = Stopwatch()..start();
  final result = await MatchService(weather).run(
    MatchRequest(
      race: race,
      sport: Sport.run,
      home: (name: home.name, latitude: home.latitude, longitude: home.longitude),
      distanceKm: 15,
      rangeKm: 150,
      mode: MatchMode.specificDate,
      date: date,
      periodDays: 14,
      weights: MatchWeights.forSport(Sport.run),
    ),
    onProgress: (s) => stdout.writeln('  … $s'),
  );
  stdout.writeln('== Match ${formatDay(date)} (${watch.elapsedMilliseconds} ms, '
      '${result.spotsChecked} land spots, typical ${result.typical?.firstYear}-${result.typical?.lastYear})');
  for (final r in result.results) {
    stdout.writeln('  ${spotTitle(r.spot)} — ${scoreText(r.best.score)} | '
        '${windowText(r)} | ${comparisonParts(r.best.conditions, result.target.stats).join(' · ')}');
  }
  for (final n in result.notes) {
    stdout.writeln('  NOTE: $n');
  }
}
