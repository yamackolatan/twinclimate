import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/models/fingerprint.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';

const kalmar = Place(
  name: 'Kalmar',
  region: 'Kalmar County',
  country: 'Sweden',
  latitude: 56.6634,
  longitude: 16.3568,
);

Race ironmanKalmar({String name = 'Ironman Kalmar', int startHour = 7}) => Race(
  id: 'r1',
  name: name,
  place: kalmar,
  date: DateTime(2027, 8, 29),
  startHour: startHour,
  startMinute: 0,
  legs: triathlonPresets.last.legs,
);

void main() {
  group('leg timing', () {
    test('Ironman legs follow each other from the start time', () {
      final race = ironmanKalmar();
      expect(race.totalMinutes, 75 + 360 + 270);
      expect(race.windowLabel, '07:00–18:45');
      expect(
        race.legTimeline,
        'Swim 07:00–08:15 · Bike 08:15–14:15 · Run 14:15–18:45',
      );
    });

    test('single-sport race is one window', () {
      final race = Race(
        id: 'm',
        name: 'Istanbul Marathon',
        place: kalmar,
        date: DateTime(2026, 11, 8),
        startHour: 9,
        startMinute: 15,
        legs: runPresets.last.legs,
      );
      expect(race.isMultisport, isFalse);
      expect(race.windowLabel, '09:15–13:45');
    });

    test('clock wraps past midnight', () {
      final race = ironmanKalmar(startHour: 20);
      expect(race.windowLabel, '20:00–07:45');
    });

    test('time estimate from distance rounds to 5 minutes', () {
      expect(RaceLeg.estimateMinutes(Sport.run, 10), 60);
      expect(RaceLeg.estimateMinutes(Sport.bike, 90), 215);
      expect(RaceLeg.estimateMinutes(Sport.swim, 0.1), 5);
    });
  });

  group('quick-fill buttons', () {
    test('triathlon presets when all three sports are ticked', () {
      expect(
        presetsFor({Sport.swim, Sport.bike, Sport.run}).map((p) => p.label),
        ['Sprint', 'Olympic', '70.3', 'Ironman'],
      );
    });

    test('run presets for a pure running race', () {
      expect(presetsFor({Sport.run}).map((p) => p.label), [
        '10 km',
        'Half',
        'Marathon',
      ]);
    });

    test('no presets for other mixes', () {
      expect(presetsFor({Sport.bike}), isEmpty);
      expect(presetsFor({Sport.bike, Sport.run}), isEmpty);
    });

    test('every preset lists its legs in swim-bike-run order', () {
      for (final preset in [...triathlonPresets, ...runPresets]) {
        final order = [
          for (final leg in preset.legs) legOrder.indexOf(leg.sport),
        ];
        expect(order, [...order]..sort(), reason: preset.label);
      }
    });
  });

  group('fingerprint cache key', () {
    test('renaming keeps the cached fingerprint', () {
      expect(
        ironmanKalmar(name: 'IM Kalmar').fingerprintKey,
        ironmanKalmar().fingerprintKey,
      );
    });

    test('a different start time invalidates it', () {
      expect(
        ironmanKalmar(startHour: 6).fingerprintKey,
        isNot(ironmanKalmar().fingerprintKey),
      );
    });

    test('a different year of the same date keeps it (same history)', () {
      final race = ironmanKalmar();
      final nextYear = Race(
        id: race.id,
        name: race.name,
        place: race.place,
        date: DateTime(2028, 8, 29),
        startHour: 7,
        startMinute: 0,
        legs: race.legs,
      );
      expect(nextYear.fingerprintKey, race.fingerprintKey);
    });

    test('validFingerprint ignores a stale cache', () {
      final race = ironmanKalmar();
      final stale = race.withFingerprint(_fingerprint('old-key'));
      expect(stale.validFingerprint, isNull);
      final fresh = race.withFingerprint(_fingerprint(race.fingerprintKey));
      expect(fresh.validFingerprint, isNotNull);
    });
  });

  test('race with fingerprint survives a storage round-trip', () {
    final race = ironmanKalmar();
    final withFp = race.withFingerprint(_fingerprint(race.fingerprintKey));
    final restored = Race.decodeList(
      jsonEncode(jsonDecode(Race.encodeList([withFp]))),
    ).single;
    expect(restored.name, 'Ironman Kalmar');
    expect(restored.date, DateTime(2027, 8, 29));
    expect(restored.legs.map((l) => l.sport), legOrder);
    expect(restored.legs[1].distanceKm, 180);
    expect(restored.validFingerprint, isNotNull);
    expect(restored.validFingerprint!.legs.single.sport, Sport.bike);
    expect(restored.validFingerprint!.overall.rainChance, 0.3);
    expect(restored.validFingerprint!.profile.first.hour, 7);
  });
}

RaceFingerprint _fingerprint(String key) {
  const stats = ConditionStats(
    temperature: Stat(18, 2),
    apparent: Stat(17, 2.5),
    humidity: Stat(78, 8),
    wind: Stat(18, 5),
    gust: Stat(30, 8),
    rainChance: 0.3,
    wetDayRainMm: 4.2,
    dayCount: 110,
    hourCount: 1320,
  );
  return RaceFingerprint(
    key: key,
    computedAt: DateTime(2026, 10, 17),
    firstYear: 2016,
    lastYear: 2025,
    yearCount: 10,
    overall: stats,
    legs: const [
      LegFingerprint(
        sport: Sport.bike,
        startOffset: 75,
        endOffset: 435,
        stats: stats,
      ),
    ],
    profile: const [ProfileHour(7, 15), ProfileHour(14, 20)],
  );
}
