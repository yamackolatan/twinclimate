import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/logic/fingerprint_builder.dart';
import 'package:twinclimate/logic/fingerprint_text.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/services/fingerprint_service.dart';
import 'package:twinclimate/services/weather_service.dart';

import 'race_test.dart' show ironmanKalmar, kalmar;

/// Predictable fake history:
/// - temperature rises 0.5 °C per hour from 12 °C at midnight
///   (07:00 -> 15.5 °C, 14:00 -> 19 °C, 18:00 -> 21 °C);
/// - humidity 80 %, wind 15 km/h, gusts 28 km/h;
/// - 2 mm of rain at 10:00 on every day whose day-of-month is divisible
///   by 3, otherwise dry.
List<PastHour> fakeHistory(DateTime firstDay, DateTime lastDay) {
  final hours = <PastHour>[];
  var day = DateTime.utc(firstDay.year, firstDay.month, firstDay.day);
  final end = DateTime.utc(lastDay.year, lastDay.month, lastDay.day)
      .add(const Duration(days: 1));
  while (day.isBefore(end)) {
    for (var h = 0; h < 24; h++) {
      hours.add(PastHour(
        time: day.add(Duration(hours: h)),
        temperatureC: 12 + h * 0.5,
        apparentC: 11 + h * 0.5,
        humidityPercent: 80,
        precipitationMm: day.day % 3 == 0 && h == 10 ? 2 : 0,
        windKmh: 15,
        gustKmh: 28,
      ));
    }
    day = day.add(const Duration(days: 1));
  }
  return hours;
}

class FakeHistoryService implements WeatherService {
  final requests = <(DateTime, DateTime)>[];

  @override
  Future<List<PastHour>> fetchHistory({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    requests.add((firstDay, lastDay));
    return fakeHistory(firstDay, lastDay);
  }

  @override
  Future<List<HourWeather>> fetchHourly({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Place>> searchPlaces(String query) => throw UnimplementedError();
}

void main() {
  final today = DateTime(2026, 10, 17);

  group('which years are used', () {
    test('late-August race seen in October uses 2017-2026: the 10 most '
        'recent years with data (owner decision 5)', () {
      expect(fingerprintYears(ironmanKalmar(), today),
          [for (var y = 2017; y <= 2026; y++) y]);
    });

    test('the same race seen in June uses 2016-2025', () {
      expect(fingerprintYears(ironmanKalmar(), DateTime(2026, 6, 1)),
          [for (var y = 2016; y <= 2025; y++) y]);
    });

    test('a date whose window already passed this year includes this year',
        () {
      final race = _runRace(DateTime(2027, 9, 20));
      expect(fingerprintYears(race, today).last, 2026);
      expect(fingerprintYears(race, today).length, 10);
    });

    test('a window not yet in the archive skips this year', () {
      final race = _runRace(DateTime(2027, 10, 12));
      expect(fingerprintYears(race, today).last, 2025);
    });

    test('history requests cover race date ±5 days', () {
      final (first, last) = historyRange(ironmanKalmar(), 2020);
      expect(first, DateTime.utc(2020, 8, 24));
      expect(last, DateTime.utc(2020, 9, 3));
    });

    test('overnight races fetch one extra day', () {
      final (_, last) = historyRange(ironmanKalmar(startHour: 20), 2020);
      expect(last, DateTime.utc(2020, 9, 4));
    });
  });

  group('the numbers (Ironman Kalmar 07:00-18:45 on fake history)', () {
    final race = ironmanKalmar();
    final years = [for (var y = 2016; y <= 2025; y++) y];
    final hours = [
      for (final y in years)
        ...fakeHistory(historyRange(race, y).$1, historyRange(race, y).$2),
    ];
    final fp = buildFingerprint(
        race: race, hours: hours, years: years, computedAt: today);

    test('uses 10 years × 11 days, race hours only', () {
      expect(fp.overall.dayCount, 110);
      // 07:00 ... 18:00 slots = 12 per day.
      expect(fp.overall.hourCount, 110 * 12);
      expect(fp.firstYear, 2016);
      expect(fp.lastYear, 2025);
    });

    test('means and spreads are right', () {
      // Mean of 15.5, 16, ..., 21.0 = 18.25
      expect(fp.overall.temperature.mean, closeTo(18.25, 1e-9));
      expect(fp.overall.temperature.sd, closeTo(1.7260, 1e-3));
      expect(fp.overall.humidity.mean, 80);
      expect(fp.overall.humidity.sd, 0);
      expect(fp.overall.wind.mean, 15);
    });

    test('rain chance = share of days with >=1 mm in race hours', () {
      // Days 24 Aug - 3 Sep: 24, 27, 30 Aug and 3 Sep are divisible by 3.
      expect(fp.overall.rainChance, closeTo(4 / 11, 1e-9));
      expect(fp.overall.wetDayRainMm, 2);
    });

    test('each leg only sees its own hours', () {
      expect(fp.legs.map((l) => l.sport), legOrder);
      final swim = fp.legs[0].stats;
      final bike = fp.legs[1].stats;
      final run = fp.legs[2].stats;
      // Swim 07:00-08:15 -> slots 07, 08.
      expect(swim.hourCount, 110 * 2);
      expect(swim.temperature.mean, closeTo(15.75, 1e-9));
      // Bike 08:15-14:15 -> slots 08 ... 14 (the 10:00 rain falls here).
      expect(bike.hourCount, 110 * 7);
      expect(bike.rainChance, closeTo(4 / 11, 1e-9));
      // Run 14:15-18:45 -> slots 14 ... 18, never rains.
      expect(run.hourCount, 110 * 5);
      expect(run.rainChance, 0);
      expect(swim.rainChance, 0);
      expect(run.temperature.mean, greaterThan(bike.temperature.mean));
    });

    test('hour-by-hour profile spans the race', () {
      expect(fp.profile.first.hour, 7);
      expect(fp.profile.last.hour, 18);
      expect(fp.profile.first.temperature, closeTo(15.5, 1e-9));
    });

    test('readable summary matches the brief\'s style', () {
      expect(
        fingerprintHeadline(race, fp),
        'Kalmar on 29 Aug, 07:00–18:45: typically 17–20°C, humid, '
        'about 15 km/h wind, 36% rain chance',
      );
      expect(profileLine(race, fp),
          'About 16°C at the 07:00 start, about 21°C at the 18:45 finish.');
    });
  });

  test('warmest-in-the-middle profiles name the peak', () {
    final race = _runRace(DateTime(2027, 6, 1), startHour: 9, minutes: 360);
    final years = [2024, 2025];
    final hours = [
      for (final y in years)
        for (final h in fakeHistory(
            historyRange(race, y).$1, historyRange(race, y).$2))
          PastHour(
            time: h.time,
            temperatureC: 20 - (h.time.hour - 13).abs().toDouble(),
            apparentC: 20,
            humidityPercent: 50,
            precipitationMm: 0,
            windKmh: 5,
            gustKmh: 10,
          ),
    ];
    final fp = buildFingerprint(
        race: race, hours: hours, years: years, computedAt: today);
    expect(profileLine(race, fp),
        'About 16°C at the 09:00 start, warmest around 13:00 (about 20°C), '
        'about 19°C at the 15:00 finish.');
    expect(conditionRows(fp.overall).last.$2, 'Dry on all 22 past race days');
  });

  test('missing data is reported, not faked', () {
    expect(
      () => buildFingerprint(
          race: ironmanKalmar(), hours: const [], years: [2025],
          computedAt: today),
      throwsA(isA<FingerprintException>()),
    );
  });

  test('service downloads one small request per year and reports progress',
      () async {
    final fake = FakeHistoryService();
    final progress = <int>[];
    final fp = await FingerprintService(fake, clock: () => today)
        .compute(ironmanKalmar(), onProgress: (done, _) => progress.add(done));
    expect(fake.requests, hasLength(10));
    expect(progress.last, 10);
    expect(fp.key, ironmanKalmar().fingerprintKey);
  });
}

Race _runRace(DateTime date, {int startHour = 9, int minutes = 60}) => Race(
      id: 'x',
      name: 'Test run',
      place: kalmar,
      date: date,
      startHour: startHour,
      startMinute: 0,
      legs: [RaceLeg(sport: Sport.run, distanceKm: 10, minutes: minutes)],
    );
