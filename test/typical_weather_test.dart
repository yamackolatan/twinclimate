import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/logic/typical_weather.dart';
import 'package:twinclimate/models/matching.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/screens/session_result_page.dart';
import 'package:twinclimate/services/match_service.dart';
import 'package:twinclimate/services/typical_weather_service.dart';

import 'fingerprint_test.dart' show FakeHistoryService;
import 'match_flow_test.dart'
    show FakeMatchWeather, homeLat, homeLon, kalmarWithFingerprint;

/// FakeHistoryService that also answers forecasts (for the kit screen).
class HistoryAndForecast extends FakeMatchWeather {}

void main() {
  final now = DateTime(2026, 10, 18, 9);

  group('forecast reach (16 days)', () {
    test('today + 15 is the last forecast day', () {
      expect(lastForecastDay(now), DateTime(2026, 11, 2));
      expect(beyondForecast(DateTime(2026, 11, 2, 23), now), isFalse);
      expect(beyondForecast(DateTime(2026, 11, 3, 6), now), isTrue);
    });

    test('says when the real forecast becomes available', () {
      expect(forecastAvailableFrom(DateTime(2027, 3, 20, 8)),
          DateTime(2027, 3, 5));
    });
  });

  group('typical hours from history', () {
    // Two years, 20 Mar ± 1 day, hour 08:00 only:
    // temperatures 10/12/14 (2024) and 12/14/16 (2025) → mean 13;
    // rain in 2 of the 6 readings → 33 %; cloud 20 % → clear code.
    List<PastHour> history() => [
          for (final (year, base) in [(2024, 10.0), (2025, 12.0)])
            for (var d = -1; d <= 1; d++)
              PastHour(
                time: DateTime.utc(year, 3, 20 + d, 8),
                temperatureC: base + (d + 1) * 2,
                apparentC: base + (d + 1) * 2 - 1,
                humidityPercent: 70,
                precipitationMm: d == 0 ? 0.6 : 0,
                windKmh: 12,
                gustKmh: 20,
                radiationWm2: 300,
                cloudCoverPercent: 20,
              ),
        ];

    test('averages the same clock hour over years and nearby days', () {
      final hours = typicalHours(
        history: history(),
        years: [2024, 2025],
        date: DateTime(2027, 3, 20),
        slots: [DateTime(2027, 3, 20, 8), DateTime(2027, 3, 20, 9)],
        spread: 1,
      );
      expect(hours, hasLength(1)); // no 09:00 records → left out
      final h = hours.single;
      expect(h.time, DateTime(2027, 3, 20, 8));
      expect(h.temperatureC, closeTo(13, 1e-9));
      expect(h.apparentC, closeTo(12, 1e-9));
      expect(h.precipProbabilityPercent, closeTo(100 / 3, 1e-9));
      expect(h.precipitationMm, closeTo(0.2, 1e-9));
      expect(h.weatherCode, 0);
      expect(h.isDay, isTrue);
      expect(h.radiationWm2, 300);
    });

    test('rainy in most years shows as rain', () {
      final wet = [
        for (final h in history())
          PastHour(
            time: h.time,
            temperatureC: 10,
            apparentC: 9,
            humidityPercent: 90,
            precipitationMm: 1,
            windKmh: 10,
            gustKmh: 20,
          ),
      ];
      final h = typicalHours(
        history: wet,
        years: [2024, 2025],
        date: DateTime(2027, 3, 20),
        slots: [DateTime(2027, 3, 20, 8)],
        spread: 1,
      ).single;
      expect(h.weatherCode, 61);
      expect(h.precipProbabilityPercent, 100);
    });
  });

  test('service: one request per year for a session, last 10 years',
      () async {
    final fake = FakeHistoryService();
    final start = DateTime(2027, 3, 20, 8);
    final slots = [start, start.add(const Duration(hours: 1))];
    final t = await TypicalWeatherService(fake, clock: () => now).forSession(
      const Place(
          name: 'Belgrad Forest',
          region: '',
          country: '',
          latitude: 41.18,
          longitude: 28.99),
      slots,
    );
    expect(fake.requests, hasLength(10));
    // Seen from Oct 2026, March 2026 is already recorded.
    expect(t.firstYear, 2017);
    expect(t.lastYear, 2026);
    expect(t.forecast.hours.map((h) => h.time), slots);
    // fakeHistory: 12 + 0.5 × hour → 16° at 08:00.
    expect(t.forecast.hours.first.temperatureC, closeTo(16, 1e-9));
    expect(t.feelsSpread.mean, closeTo(15.25, 1e-9));
  });

  group('race matching beyond the forecast', () {
    MatchRequest request(MatchMode mode, DateTime date,
            {DateTime? periodStart, int periodDays = 14}) =>
        MatchRequest(
          race: kalmarWithFingerprint(),
          sport: Sport.run,
          home: (name: 'Belgrad Forest', latitude: homeLat, longitude: homeLon),
          distanceKm: 10,
          rangeKm: 150,
          mode: mode,
          date: date,
          periodDays: periodDays,
          periodStart: periodStart,
          weights: MatchWeights.forSport(Sport.run),
          window: const TrainingWindow(daylightOnly: false),
        );

    test('a date months away is ranked by typical weather', () async {
      final weather = FakeMatchWeather();
      final result = await MatchService(weather, clock: () => now)
          .run(request(MatchMode.specificDate, DateTime(2027, 5, 15)));
      expect(result.typical, isNotNull);
      expect(result.typical!.firstYear, 2017);
      expect(result.typical!.forPeriod, isFalse);
      expect(weather.manyHistoryCalls, hasLength(10));
      expect(weather.manyCalls, isEmpty); // no forecast requested
      expect(result.results, hasLength(5));
      for (final r in result.results) {
        expect(r.best.start.month, 5);
        expect(r.best.start.day, 15);
        expect(r.spot.latitude, lessThanOrEqualTo(homeLat + 0.3));
      }
    });

    test('repeating a far-ahead search downloads nothing new', () async {
      final weather = FakeMatchWeather();
      final req = request(MatchMode.specificDate, DateTime(2027, 7, 1));
      await MatchService(weather, clock: () => now).run(req);
      await MatchService(weather, clock: () => now).run(req);
      expect(weather.manyHistoryCalls, hasLength(10));
    });

    test('a period reaching past the forecast uses its middle day', () async {
      final result = await MatchService(FakeMatchWeather(), clock: () => now)
          .run(request(MatchMode.period, now,
              periodStart: DateTime(2027, 1, 10), periodDays: 7));
      expect(result.typical!.forPeriod, isTrue);
      expect(result.typical!.date, DateTime(2027, 1, 13));
    });

    test('within the forecast nothing changes', () async {
      final weather = FakeMatchWeather();
      final result = await MatchService(weather, clock: () => now)
          .run(request(MatchMode.specificDate, DateTime(2026, 10, 24)));
      expect(result.typical, isNull);
      expect(weather.manyHistoryCalls, isEmpty);
    });
  });

  testWidgets('kit screen beyond 16 days shows typical weather, clearly',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final soon = DateTime.now();
    final start = DateTime(soon.year, soon.month, soon.day + 60, 8);
    await tester.pumpWidget(MaterialApp(
      home: SessionResultPage(
        plan: SessionPlan(
          sport: Sport.run,
          place: presetPlaces.first,
          start: start,
          distanceKm: 10,
        ),
        weather: HistoryAndForecast(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Typical weather, not a forecast'),
        findsOneWidget);
    expect(find.textContaining('Typically feels like'), findsOneWidget);
    expect(
        find.textContaining(
            'The real forecast is available from ${formatDay(start.subtract(const Duration(days: 15)))}'),
        findsOneWidget);
    expect(find.text('Your kit'), findsOneWidget);
  });
}
