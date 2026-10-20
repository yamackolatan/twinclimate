import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/logic/fingerprint_builder.dart';
import 'package:twinclimate/models/matching.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/screens/quick_session_page.dart';
import 'package:twinclimate/screens/session_result_page.dart';
import 'package:twinclimate/services/match_service.dart';
import 'package:twinclimate/services/place_namer.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'fingerprint_test.dart' show fakeHistory;
import 'race_flow_test.dart' show FakeRaceWeather;
import 'race_test.dart' show ironmanKalmar;

const homeLat = 52.3580;
const homeLon = 4.8686;

/// Stand-in forecasts: spots north of home are "sea" (height 0); on land,
/// temperature gets closer to the Kalmar run leg the farther east a spot
/// is, and rises through the day.
class FakeMatchWeather extends FakeRaceWeather {
  final manyCalls = <int>[];

  static List<HourWeather> _forecast(
    double lat,
    double lon,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    final hours = <HourWeather>[];
    for (
      var day = DateTime(firstDay.year, firstDay.month, firstDay.day);
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 1))
    ) {
      for (var h = 0; h < 24; h++) {
        hours.add(
          HourWeather(
            time: DateTime(day.year, day.month, day.day, h),
            temperatureC: 8 + h * 0.5 + (lon - homeLon) * 3,
            apparentC: 8 + h * 0.5,
            humidityPercent: 75,
            precipProbabilityPercent: 20,
            precipitationMm: 0,
            windKmh: 12,
            gustKmh: 25,
            weatherCode: 2,
            isDay: h >= 7 && h < 18,
          ),
        );
      }
    }
    return hours;
  }

  @override
  Future<List<SpotForecast>> fetchHourlyMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    manyCalls.add(points.length);
    return [
      for (final p in points)
        SpotForecast(
          elevationM: p.$1 > homeLat + 0.3 ? 0 : 50,
          hours: _forecast(p.$1, p.$2, firstDay, lastDay),
        ),
    ];
  }

  @override
  Future<List<SpotHistory>> fetchHistoryMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final all = await super.fetchHistoryMany(
      points: points,
      firstDay: firstDay,
      lastDay: lastDay,
    );
    return [
      for (var i = 0; i < points.length; i++)
        SpotHistory(
          elevationM: points[i].$1 > homeLat + 0.3 ? 0 : 50,
          hours: all[i].hours,
        ),
    ];
  }

  @override
  Future<List<HourWeather>> fetchHourly({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async => _forecast(place.latitude, place.longitude, firstDay, lastDay);
}

class FakeNamer implements PlaceNamer {
  var calls = 0;

  @override
  Future<String?> nameFor(double latitude, double longitude) async =>
      'Village ${++calls}';
}

Race kalmarWithFingerprint() {
  final race = ironmanKalmar();
  final years = [for (var y = 2016; y <= 2025; y++) y];
  return race.withFingerprint(
    buildFingerprint(
      race: race,
      hours: [
        for (final y in years)
          ...fakeHistory(historyRange(race, y).$1, historyRange(race, y).$2),
      ],
      years: years,
      computedAt: DateTime(2026, 10, 18),
    ),
  );
}

void main() {
  final now = DateTime(2026, 10, 18, 7, 0);

  MatchRequest request(
    MatchMode mode, {
    double rangeKm = 150,
    DateTime? periodStart,
    int periodDays = 14,
  }) => MatchRequest(
    race: kalmarWithFingerprint(),
    sport: Sport.run,
    home: (name: 'Vondelpark', latitude: homeLat, longitude: homeLon),
    distanceKm: 15,
    rangeKm: rangeKm,
    mode: mode,
    date: DateTime(2026, 10, 24),
    periodDays: periodDays,
    periodStart: periodStart,
    weights: MatchWeights.forSport(Sport.run),
  );

  group('match service', () {
    test(
      'specific date: sea spots dropped, five places ranked best-first',
      () async {
        final weather = FakeMatchWeather();
        final result = await MatchService(
          weather,
          clock: () => now,
        ).run(request(MatchMode.specificDate));
        expect(weather.manyCalls, [43]);
        expect(result.spotsChecked, lessThan(43));
        expect(result.results, hasLength(5));
        for (final r in result.results) {
          expect(r.spot.latitude, lessThanOrEqualTo(homeLat + 0.3));
          expect(r.best.start.day, 24);
          expect(r.windowFirstStart.isAfter(r.best.start), isFalse);
          expect(r.windowLastStart.isBefore(r.best.start), isFalse);
        }
        // As shown (whole %), best first; equal shown scores go closer first.
        final scores = [for (final r in result.results) r.best.score.round()];
        expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
        final places = {
          for (final r in result.results) (r.spot.latitude, r.spot.longitude),
        };
        expect(places, hasLength(5));
        expect(result.target.label, 'run leg 14:15–18:45');
      },
    );

    test('best day in a period scans the next 14 days', () async {
      final weather = FakeMatchWeather();
      final result = await MatchService(
        weather,
        clock: () => now,
      ).run(request(MatchMode.period));
      final days = {for (final r in result.results) r.best.start.day};
      expect(result.results, hasLength(5));
      for (final day in days) {
        expect(day, inInclusiveRange(18, 31));
      }
    });

    test('own dates from the calendar: only those days are searched', () async {
      final weather = FakeMatchWeather();
      final result = await MatchService(weather, clock: () => now).run(
        request(
          MatchMode.period,
          periodStart: DateTime(2026, 10, 23),
          periodDays: 3,
        ),
      );
      expect(result.results, hasLength(5));
      for (final r in result.results) {
        expect(r.best.start.day, inInclusiveRange(23, 25));
      }
    });

    test('dates beyond the 16-day forecast use typical weather', () async {
      final result = await MatchService(FakeMatchWeather(), clock: () => now)
          .run(
            request(
              MatchMode.period,
              periodStart: DateTime(2026, 11, 20),
              periodDays: 3,
            ),
          );
      expect(result.typical, isNotNull);
      expect(result.typical!.date, DateTime(2026, 11, 21));
      expect(result.results, hasLength(5));
    });
  });

  testWidgets('switch to Match my race, search, see places and time windows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
    await store.saveRace(kalmarWithFingerprint());
    final weather = FakeMatchWeather();
    final namer = FakeNamer();

    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(store: store, weather: weather, namer: namer),
      ),
    );

    await tester.tap(find.text('Match my race'));
    await tester.pumpAndSettle();
    expect(find.text('Race to match: Ironman Kalmar'), findsOneWidget);
    expect(find.text('Travel range'), findsOneWidget);
    expect(find.text('Specific date'), findsOneWidget);
    expect(find.text('Advanced: what matters most'), findsOneWidget);

    // Training hours and the optional daylight rule, remembered.
    expect(find.text('When can you train?'), findsOneWidget);
    expect(find.text('From 06:00'), findsOneWidget);
    expect(find.text('Until 20:00'), findsOneWidget);
    await tester.tap(find.text('Daylight only'));
    await tester.pumpAndSettle();
    expect(store.trainingWindow.daylightOnly, isFalse);
    await tester.tap(find.text('Daylight only'));
    await tester.pumpAndSettle();
    expect(store.trainingWindow.daylightOnly, isTrue);

    // Period mode offers 7 or 14 days, or the user's own dates.
    await tester.tap(find.text('Best day in a period'));
    await tester.pumpAndSettle();
    expect(find.text('Next 14 days'), findsOneWidget);
    expect(find.text('Choose dates'), findsOneWidget);
    expect(
      find.textContaining('typical weather from the last 10 years'),
      findsOneWidget,
    );
    await tester.tap(find.text('Specific date'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vondelpark'));
    await tester.pump();
    await tester.tap(find.text('Find race-like conditions'));
    await tester.pumpAndSettle();

    expect(find.text('Race-like conditions'), findsOneWidget);
    expect(
      find.textContaining('Run leg 14:15–18:45: typically'),
      findsOneWidget,
    );
    expect(find.textContaining('1. Village 1'), findsOneWidget);
    expect(find.textContaining('5. Village 5'), findsOneWidget);
    expect(find.textContaining('% match'), findsNWidgets(5));
    expect(find.textContaining('best start'), findsNWidgets(5));
    expect(find.textContaining('you\'d train'), findsNWidgets(5));
    expect(find.textContaining('race typical'), findsNWidgets(5));
    expect(namer.calls, 5);

    // One tap from "where" to "what to wear".
    await tester.tap(find.text('See forecast & kit').first);
    await tester.pumpAndSettle();
    expect(find.byType(SessionResultPage), findsOneWidget);
  });

  testWidgets('pick your own dates from the calendar', (tester) async {
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
    await store.saveRace(kalmarWithFingerprint());
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(
          store: store,
          weather: FakeMatchWeather(),
          namer: FakeNamer(),
        ),
      ),
    );
    await tester.tap(find.text('Match my race'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Best day in a period'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose dates'));
    await tester.pumpAndSettle();
    expect(find.text('Pick the days you could train'), findsOneWidget);
    await tester.tap(find.text('Use these dates'));
    await tester.pumpAndSettle();

    // The chip now shows the chosen range (today + 6 days by default).
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 6));
    final label = '${formatDay(start)} – ${formatDay(end)}';
    expect(find.text(label), findsOneWidget);

    await tester.tap(find.text('Vondelpark'));
    await tester.pump();
    await tester.tap(find.text('Find race-like conditions'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'best day between ${formatDay(start)} and ${formatDay(end)}',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('% match'), findsNWidgets(5));
  });

  testWidgets('a training window shorter than the session blocks the search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'trainFromMinutes': 7 * 60,
      'trainUntilMinutes': 7 * 60 + 30,
    });
    final store = await PrefsStore.load();
    await store.saveRace(kalmarWithFingerprint());
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(
          store: store,
          weather: FakeMatchWeather(),
          namer: FakeNamer(),
        ),
      ),
    );
    await tester.tap(find.text('Match my race'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vondelpark'));
    await tester.pump();
    expect(
      find.textContaining(
        'Your training window (07:00–07:30) is '
        'shorter than this session',
      ),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Find race-like conditions'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('no race saved: no match switch, Quick Session as before', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(store: store, weather: FakeMatchWeather()),
      ),
    );
    expect(find.text('Match my race'), findsNothing);
    expect(find.text('Quick Session'), findsOneWidget);
  });
}
