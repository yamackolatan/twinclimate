import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/logic/fingerprint_builder.dart';
import 'package:twinclimate/logic/match_engine.dart';
import 'package:twinclimate/logic/match_text.dart';
import 'package:twinclimate/models/fingerprint.dart';
import 'package:twinclimate/models/matching.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';

import 'fingerprint_test.dart' show fakeHistory;
import 'race_test.dart' show ironmanKalmar, kalmar;

/// Race target: 18 ± 2 °C, 75 ± 10 % humidity, 15 ± 5 km/h wind, 30 % rain.
const target = ConditionStats(
  temperature: Stat(18, 2),
  apparent: Stat(17, 2),
  humidity: Stat(75, 10),
  wind: Stat(15, 5),
  gust: Stat(28, 6),
  rainChance: 0.3,
  wetDayRainMm: 4,
  dayCount: 110,
  hourCount: 1000,
);

const runWeights = MatchWeights(
    temperature: 0.35, humidity: 0.30, wind: 0.20, rain: 0.15);

HourWeather hour(DateTime time,
        {double temp = 18,
        double humidity = 75,
        double wind = 15,
        double rainProb = 30}) =>
    HourWeather(
      time: time,
      temperatureC: temp,
      apparentC: temp,
      humidityPercent: humidity,
      precipProbabilityPercent: rainProb,
      precipitationMm: 0,
      windKmh: wind,
      gustKmh: wind * 2,
      weatherCode: 1,
      isDay: true,
    );

/// A day where temperature is [peak] at 09:00 and drops 2 °C per hour away
/// from it; everything else is race-typical.
Map<DateTime, HourWeather> peakedDay(DateTime day, {double peak = 18}) => {
      for (var h = 0; h < 24; h++)
        DateTime(day.year, day.month, day.day, h): hour(
            DateTime(day.year, day.month, day.day, h),
            temp: peak - 2.0 * (h - 9).abs()),
    };

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 6371 * 2 * math.asin(math.sqrt(a));
}

void main() {
  group('search spots', () {
    test('43 spots in rings out to the travel range, starting at home', () {
      final spots = generateSpots(41.18, 28.99, 150);
      expect(spots, hasLength(43));
      expect(spots.first.isHome, isTrue);
      expect(spots.map((s) => s.distanceKm).toSet(),
          {0, 37.5, 75, 112.5, 150});
      for (final s in spots) {
        expect(haversineKm(41.18, 28.99, s.latitude, s.longitude),
            closeTo(s.distanceKm, 0.5));
      }
    });

    test('every direction is covered on the outer ring', () {
      final outer = generateSpots(41.18, 28.99, 100)
          .where((s) => s.distanceKm == 100)
          .map(spotDirection)
          .map((d) => d.split(' ').last)
          .toSet();
      expect(outer, containsAll(['north', 'east', 'south', 'west']));
    });

    test('readable directions', () {
      const spot = Spot(
          latitude: 0, longitude: 0, distanceKm: 38.4, bearingDegrees: 315);
      expect(spotDirection(spot), '38 km north-west');
      expect(spotTitle(spot), '38 km north-west');
      expect(spotTitle(spot.copyWith(name: 'Kilyos')), 'Kilyos');
      expect(spotDetails(spot.copyWith(name: 'Kilyos', elevationM: 12.3)),
          '38 km north-west · 12 m altitude');
    });
  });

  group('similarity score', () {
    test('race-typical conditions score 100 %', () {
      const c = SessionConditions(
          temperature: 18, humidity: 75, wind: 15, rainLikelihood: 0.3);
      expect(similarityScore(c, target, runWeights), closeTo(100, 1e-9));
    });

    test('one normal spread off on everything scores about 70 %', () {
      const c = SessionConditions(
          temperature: 20, humidity: 85, wind: 20, rainLikelihood: 0.65);
      expect(similarityScore(c, target, runWeights), closeTo(70.7, 0.1));
    });

    test('farther from race day always scores lower', () {
      double scoreAt(double temp) => similarityScore(
          SessionConditions(
              temperature: temp, humidity: 75, wind: 15, rainLikelihood: 0.3),
          target,
          runWeights);
      expect(scoreAt(19), greaterThan(scoreAt(21)));
      expect(scoreAt(21), greaterThan(scoreAt(26)));
      expect(scoreAt(17), closeTo(scoreAt(19), 1e-9));
    });

    test('weights decide what matters: windy day hurts a bike more', () {
      const windy = SessionConditions(
          temperature: 18, humidity: 75, wind: 30, rainLikelihood: 0.3);
      expect(
          similarityScore(windy, target, MatchWeights.forSport(Sport.bike)),
          lessThan(similarityScore(
              windy, target, MatchWeights.forSport(Sport.run))));
    });

    test('sport defaults follow the brief and sum to 100 %', () {
      final run = MatchWeights.forSport(Sport.run);
      expect([run.temperature, run.humidity, run.wind, run.rain],
          [0.35, 0.30, 0.20, 0.15]);
      for (final sport in Sport.values) {
        final w = MatchWeights.forSport(sport).normalised;
        expect(w.temperature + w.humidity + w.wind + w.rain, closeTo(1, 1e-9));
      }
      expect(MatchWeights.forSport(Sport.bike).wind,
          greaterThan(MatchWeights.forSport(Sport.bike).temperature));
    });

    test('all-zero custom weights fall back to equal weights', () {
      const zero =
          MatchWeights(temperature: 0, humidity: 0, wind: 0, rain: 0);
      expect(zero.normalised.temperature, 0.25);
    });
  });

  group('session conditions', () {
    final day = DateTime(2026, 10, 24);
    test('averages the session hours; rain is the highest chance', () {
      final byHour = {
        for (var h = 0; h < 24; h++)
          DateTime(2026, 10, 24, h): hour(DateTime(2026, 10, 24, h),
              temp: h.toDouble(), rainProb: h == 9 ? 60 : 10),
      };
      // 08:00 + 90 min -> 08:00 and 09:00 slots.
      final c = sessionConditions(
          byHour, day.add(const Duration(hours: 8)), 90)!;
      expect(c.temperature, 8.5);
      expect(c.rainLikelihood, 0.6);
    });

    test('sessions running into darkness are not recommended', () {
      final byHour = {
        for (var h = 0; h < 24; h++)
          DateTime(2026, 10, 24, h): HourWeather(
            time: DateTime(2026, 10, 24, h),
            temperatureC: 18,
            apparentC: 18,
            humidityPercent: 75,
            precipProbabilityPercent: 30,
            precipitationMm: 0,
            windKmh: 15,
            gustKmh: 30,
            weatherCode: 1,
            isDay: h >= 7 && h <= 17,
          ),
      };
      // 15:00 + 90 min finishes 16:30: daylight throughout.
      expect(sessionConditions(byHour, DateTime(2026, 10, 24, 15), 90),
          isNotNull);
      // 17:00 + 60 min finishes at 18:00, which is dark.
      expect(sessionConditions(byHour, DateTime(2026, 10, 24, 17), 60),
          isNull);
      // 16:00 + 90 min finishes 17:30, nearest hour 18:00: dark.
      expect(sessionConditions(byHour, DateTime(2026, 10, 24, 16), 90),
          isNull);
      // 16:00 + 70 min finishes 17:10, nearest hour 17:00: still light.
      expect(sessionConditions(byHour, DateTime(2026, 10, 24, 16), 70),
          isNotNull);
      // 06:00 starts in the dark.
      expect(sessionConditions(byHour, DateTime(2026, 10, 24, 6), 60),
          isNull);
    });

    test('missing forecast hours give no score instead of a fake one', () {
      final c = sessionConditions(const {}, day, 60);
      expect(c, isNull);
    });
  });

  group('best time and time window', () {
    final day = DateTime(2026, 10, 24);
    const spot = Spot(
        latitude: 41, longitude: 29, distanceKm: 0, bearingDegrees: 0);

    PlaceResult best(Map<DateTime, HourWeather> byHour,
            {DateTime? notBefore, List<DateTime>? days}) =>
        bestForSpot(
          spot: spot,
          byHour: byHour,
          days: days ?? [day],
          durationMinutes: 60,
          target: target,
          weights: runWeights,
          notBefore: notBefore,
        )!;

    test('finds the best start and a window of good neighbouring starts',
        () {
      final r = best(peakedDay(day));
      expect(r.best.start, DateTime(2026, 10, 24, 9));
      expect(r.best.score, closeTo(100, 1e-9));
      // 08:00 and 10:00 are 2 °C (one spread) off -> ~92 %, still within
      // 8 points; 07:00 / 11:00 are 4 °C off -> well below.
      expect(r.windowFirstStart, DateTime(2026, 10, 24, 8));
      expect(r.windowLastStart, DateTime(2026, 10, 24, 10));
      expect(windowText(r),
          'Start between 08:00 and 10:00 → you\'d train 08:00–11:00');
      expect(r.dayScores.first.start.hour, firstStartHour);
      expect(r.dayScores.last.start.hour, lastStartHour);
    });

    test('a sharp peak gives a single start time', () {
      final byHour = peakedDay(day)
        ..updateAll((time, h) => hour(time, temp: time.hour == 9 ? 18 : 30));
      final r = best(byHour);
      expect(r.windowFirstStart, r.windowLastStart);
      expect(windowText(r), 'Start at 09:00 → you\'d train 09:00–10:00');
    });

    test('start times already in the past are skipped', () {
      final r = best(peakedDay(day),
          notBefore: DateTime(2026, 10, 24, 11, 30));
      expect(r.best.start.hour, 12);
      expect(r.dayScores.first.start.hour, 12);
    });

    test('period mode picks the best day', () {
      final day2 = day.add(const Duration(days: 1));
      final byHour = {
        ...peakedDay(day)
          ..updateAll((time, h) => hour(time, temp: 25)),
        ...peakedDay(day2),
      };
      final r = best(byHour, days: [day, day2]);
      expect(r.best.start, DateTime(2026, 10, 25, 9));
    });
  });

  test('ranking: best first, five different places, ties go closer', () {
    PlaceResult result(double score, double distance) => PlaceResult(
          spot: Spot(
              latitude: distance,
              longitude: 0,
              distanceKm: distance,
              bearingDegrees: 0),
          best: MatchOption(
            start: DateTime(2026, 10, 24, 9),
            conditions: const SessionConditions(
                temperature: 18, humidity: 75, wind: 15, rainLikelihood: 0.3),
            score: score,
          ),
          windowFirstStart: DateTime(2026, 10, 24, 9),
          windowLastStart: DateTime(2026, 10, 24, 9),
          durationMinutes: 60,
          dayScores: const [],
        );
    final ranked = rankResults([
      result(60, 10),
      result(90, 100),
      result(90.2, 20),
      result(75, 5),
      result(50, 1),
      result(80, 40),
    ]);
    expect(ranked, hasLength(5));
    expect(ranked.map((r) => r.spot.distanceKm), [20, 100, 40, 5, 10]);
  });

  group('honest adaptation notes', () {
    PlaceResult withConditions(SessionConditions c, double score) =>
        PlaceResult(
          spot: const Spot(
              latitude: 0, longitude: 0, distanceKm: 0, bearingDegrees: 0),
          best: MatchOption(
              start: DateTime(2026, 10, 24, 9), conditions: c, score: score),
          windowFirstStart: DateTime(2026, 10, 24, 9),
          windowLastStart: DateTime(2026, 10, 24, 9),
          durationMinutes: 60,
          dayScores: const [],
        );

    test('good matches need no notes', () {
      expect(
          adaptationNotes(
            best: withConditions(
                const SessionConditions(
                    temperature: 18, humidity: 75, wind: 15,
                    rainLikelihood: 0.3),
                95),
            target: target,
            sport: Sport.run,
            rangeKm: 150,
          ),
          isEmpty);
    });

    test('much warmer than race day: pace advice (brief example)', () {
      final notes = adaptationNotes(
        best: withConditions(
            const SessionConditions(
                temperature: 24, humidity: 75, wind: 15, rainLikelihood: 0.3),
            40),
        target: target,
        sport: Sport.run,
        rangeKm: 150,
      );
      expect(notes.single,
          startsWith('About 6°C warmer than race day. Run at an easier pace '
              '(roughly 10–15 sec/km slower)'));
    });

    test('race hotter than anything nearby: heat acclimatisation pointer',
        () {
      final notes = adaptationNotes(
        best: withConditions(
            const SessionConditions(
                temperature: 10, humidity: 50, wind: 30, rainLikelihood: 0.3),
            20),
        target: target,
        sport: Sport.bike,
        rangeKm: 150,
      );
      expect(notes, hasLength(3));
      expect(notes[0], contains('heat acclimatisation'));
      expect(notes[1], startsWith('Drier air than race day (50% vs 75%)'));
      expect(notes[2], startsWith('Windier than race day (30 vs 15 km/h)'));
    });
  });

  group('which race conditions are matched (owner decision 1)', () {
    final race = ironmanKalmar();
    final years = [for (var y = 2016; y <= 2025; y++) y];
    final fp = buildFingerprint(
      race: race,
      hours: [
        for (final y in years)
          ...fakeHistory(historyRange(race, y).$1, historyRange(race, y).$2),
      ],
      years: years,
      computedAt: DateTime(2026, 10, 18),
    );
    final withFp = race.withFingerprint(fp);

    test('training run matches the race\'s run leg', () {
      final t = MatchTarget.forRace(withFp, Sport.run)!;
      expect(t.isLeg, isTrue);
      expect(t.label, 'run leg 14:15–18:45');
      expect(t.stats.temperature.mean, fp.legs.last.stats.temperature.mean);
    });

    test('training bike matches the bike leg', () {
      expect(MatchTarget.forRace(withFp, Sport.bike)!.label,
          'bike leg 08:15–14:15');
    });

    test('a sport the race lacks matches the whole race window', () {
      final marathon = Race(
        id: 'm',
        name: 'Marathon',
        place: kalmar,
        date: DateTime(2027, 8, 29),
        startHour: 9,
        startMinute: 0,
        legs: runPresets.last.legs,
      );
      final years2 = [2024, 2025];
      final mfp = buildFingerprint(
        race: marathon,
        hours: [
          for (final y in years2)
            ...fakeHistory(
                historyRange(marathon, y).$1, historyRange(marathon, y).$2),
        ],
        years: years2,
        computedAt: DateTime(2026, 10, 18),
      );
      final t = MatchTarget.forRace(marathon.withFingerprint(mfp), Sport.bike)!;
      expect(t.isLeg, isFalse);
      expect(t.label, 'race hours 09:00–13:30');
    });

    test('no target until the race-day climate exists', () {
      expect(MatchTarget.forRace(race, Sport.run), isNull);
    });
  });
}
