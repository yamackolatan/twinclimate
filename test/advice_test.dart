import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twinclimate/logic/best_time.dart';
import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/logic/weather_text.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/services/weather_service.dart';

final _day = DateTime(2026, 11, 7);
final _rise = DateTime(2026, 11, 7, 7, 52);
final _set = DateTime(2026, 11, 7, 17, 5);

HourWeather hour(
  int h, {
  double feels = 12,
  double rain = 10,
  double mm = 0,
  double wind = 10,
  double? uv,
}) => HourWeather(
  time: DateTime(_day.year, _day.month, _day.day, h),
  temperatureC: feels + 2,
  apparentC: feels,
  humidityPercent: 70,
  precipProbabilityPercent: rain,
  precipitationMm: mm,
  windKmh: wind,
  gustKmh: wind + 10,
  weatherCode: rain >= 50 ? 61 : 1,
  isDay: h >= 8 && h < 17,
  uvIndex: uv,
  windDirectionDeg: 225,
  sunrise: _rise,
  sunset: _set,
);

SessionPlan plan(
  int startHour, {
  Sport sport = Sport.run,
  double km = 10,
  bool pool = false,
  double? pace,
}) => SessionPlan(
  sport: sport,
  place: presetPlaces.first,
  start: DateTime(_day.year, _day.month, _day.day, startHour),
  distanceKm: km,
  pool: pool,
  paceHoursPerKm: pace,
);

List<GearItem> kitFor(SessionPlan p, {double feels = 12, double? uv}) {
  final f = SessionForecast([
    for (final t in p.windowHours) hour(t.hour, feels: feels, uv: uv),
  ]);
  return buildKitForPlan(p, f);
}

Set<String> names(List<GearItem> kit) => {for (final i in kit) i.name};

void main() {
  group('dark sessions', () {
    test('a run before sunrise gets a headlamp and reflective gear', () {
      final kit = kitFor(plan(7));
      expect(
        names(kit),
        containsAll(['Headlamp or chest light', 'Reflective vest or bands']),
      );
      final lamp = kit.firstWhere((i) => i.name == 'Headlamp or chest light');
      expect(lamp.reason, contains('sunrise is at 07:52'));
      expect(lamp.part, BodyPart.head);
    });

    test('a ride finishing after sunset gets lights', () {
      final kit = kitFor(plan(16, sport: Sport.bike, km: 40));
      final lights = kit.firstWhere(
        (i) => i.name == 'Front and rear bike lights',
      );
      expect(lights.reason, contains('sunset is at 17:05'));
    });

    test('twilight counts as light: no lights just after sunset', () {
      // 5 km run 16:45-17:15; sunset 17:05 -> within 20 min of twilight.
      final p = SessionPlan(
        sport: Sport.run,
        place: presetPlaces.first,
        start: DateTime(_day.year, _day.month, _day.day, 16, 45),
        distanceKm: 5,
      );
      expect(names(kitFor(p)), isNot(contains('Headlamp or chest light')));
    });

    test('a daylight run gets no lights', () {
      expect(
        names(kitFor(plan(10))),
        isNot(contains('Headlamp or chest light')),
      );
    });
  });

  test('UV 3 or more brings sunscreen; low UV does not', () {
    expect(names(kitFor(plan(12), uv: 5)), contains('Sunscreen (SPF 30+)'));
    expect(
      names(kitFor(plan(12), uv: 1)),
      isNot(contains('Sunscreen (SPF 30+)')),
    );
  });

  group('water and food', () {
    test('short cool run: nothing to carry', () {
      final kit = kitFor(plan(10, km: 5));
      expect(names(kit), isNot(contains('Handheld bottle or soft flask')));
    });

    test('2 h run: bottle and a gel', () {
      final kit = kitFor(plan(10, km: 20));
      expect(
        names(kit),
        containsAll([
          'Handheld bottle or soft flask',
          'Gel or snack in a pocket',
        ]),
      );
    });

    test('long warm ride: electrolytes in the bottles', () {
      final kit = kitFor(plan(9, sport: Sport.bike, km: 60), feels: 24);
      expect(names(kit), contains('Bottles with electrolytes'));
      expect(names(kit), contains('Bar or gels in your jersey pocket'));
    });
  });

  test('pool swim: no wetsuit or neoprene, even in cold air', () {
    final kit = kitFor(
      plan(10, sport: Sport.swim, km: 2, pool: true),
      feels: 2,
    );
    final n = names(kit);
    expect(n, containsAll(['Swim cap', 'Goggles', 'Swimsuit', 'Towel']));
    expect(
      n.any((x) => x.contains('Wetsuit') || x.contains('Neoprene')),
      isFalse,
    );
    for (final item in kit) {
      expect(item.reason, isNotEmpty);
    }
  });

  test('your own pace changes the session length', () {
    final fast = plan(8, km: 10, pace: 300 / 3600); // 5:00 /km
    expect(fast.durationHours, closeTo(50 / 60, 0.001));
    expect(formatPace(Sport.run, 300 / 3600), '5:00 /km');
    expect(formatPace(Sport.bike, 1 / 30), '30 km/h');
    expect(formatPace(Sport.swim, 120 * 10 / 3600), '2:00 /100 m');
  });

  group('better time today', () {
    List<HourWeather> day({required Set<int> rainyHours}) => [
      for (var h = 0; h < 24; h++)
        hour(
          h,
          rain: rainyHours.contains(h) ? 80 : 10,
          mm: rainyHours.contains(h) ? 2 : 0,
        ),
    ];

    test('suggests a drier start when rain is due at the chosen time', () {
      final better = betterTime(
        plan: plan(10),
        day: day(rainyHours: {10, 11}),
        now: DateTime(2026, 11, 6),
      );
      expect(better, isNotNull);
      expect(better!.why, startsWith('Drier'));
      expect([10, 11], isNot(contains(better.start.hour)));
    });

    test('stays quiet when the chosen time is already good', () {
      expect(
        betterTime(
          plan: plan(10),
          day: day(rainyHours: {}),
          now: DateTime(2026, 11, 6),
        ),
        isNull,
      );
    });

    test('never suggests a time that has already passed', () {
      final better = betterTime(
        plan: plan(14),
        day: day(rainyHours: {14, 15}),
        now: DateTime(2026, 11, 7, 13, 30),
      );
      expect(better == null || better.start.hour > 13, isTrue);
    });
  });

  test('one-line verdict', () {
    expect(
      sessionVerdict(feelsC: 3, wet: false, windy: true),
      'Cold and windy — layer up',
    );
    expect(
      sessionVerdict(feelsC: 22, wet: false, windy: false),
      'Warm — dress light',
    );
    expect(
      sessionVerdict(feelsC: 15, wet: true, windy: true),
      'Mild, wet and windy — pack the rain jacket',
    );
  });

  test('wind direction wording', () {
    expect(compassPoint(225), 'SW');
    expect(compassPoint(359), 'N');
    expect(windPhraseWithDirection(24, 30, 225), 'breezy 24 km/h from the SW');
  });

  test('sunrise and sunset come through from the forecast', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['daily'], 'sunrise,sunset');
      return http.Response(
        jsonEncode({
          'hourly': {
            'time': ['2026-11-07T08:00'],
            'temperature_2m': [6.0],
            'apparent_temperature': [4.0],
            'wind_direction_10m': [240],
            'uv_index': [1.5],
          },
          'daily': {
            'time': ['2026-11-07'],
            'sunrise': ['2026-11-07T07:52'],
            'sunset': ['2026-11-07T17:05'],
          },
        }),
        200,
      );
    });
    final hours = await OpenMeteoWeatherService(
      client: client,
    ).fetchHourly(place: presetPlaces.first, firstDay: _day, lastDay: _day);
    expect(hours.single.sunrise, _rise);
    expect(hours.single.sunset, _set);
    expect(hours.single.windDirectionDeg, 240);
    expect(hours.single.uvIndex, 1.5);
  });
}
