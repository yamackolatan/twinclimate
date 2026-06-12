import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/session.dart';

SessionPlan plan({
  Sport sport = Sport.run,
  required DateTime start,
  required double distanceKm,
}) =>
    SessionPlan(
      sport: sport,
      place: presetPlaces.first,
      start: start,
      distanceKm: distanceKm,
    );

void main() {
  group('session window', () {
    test('15 km run at 08:00 covers 08:00 and 09:00 (the PRD example)', () {
      final p = plan(start: DateTime(2026, 6, 13, 8), distanceKm: 15);
      expect(p.durationHours, closeTo(1.5, 0.001));
      expect(p.windowHours, [
        DateTime(2026, 6, 13, 8),
        DateTime(2026, 6, 13, 9),
      ]);
      expect(p.windowLabel, '08:00–09:30');
    });

    test('short sessions still show at least two hours', () {
      final p = plan(start: DateTime(2026, 6, 13, 7), distanceKm: 3); // 18 min
      expect(p.windowHours.length, 2);
    });

    test('a 08:30 start includes the 08:00 hour card', () {
      final p = plan(start: DateTime(2026, 6, 13, 8, 30), distanceKm: 10);
      expect(p.windowHours.first, DateTime(2026, 6, 13, 8));
      // 1 h session ending 09:30 -> the 09:00 card is the last one needed.
      expect(p.windowHours.last, DateTime(2026, 6, 13, 9));
    });

    test('100 km ride at 10:00 covers four hours', () {
      final p = plan(
          sport: Sport.bike,
          start: DateTime(2026, 6, 13, 10),
          distanceKm: 100);
      expect(p.windowHours, [
        DateTime(2026, 6, 13, 10),
        DateTime(2026, 6, 13, 11),
        DateTime(2026, 6, 13, 12),
        DateTime(2026, 6, 13, 13),
      ]);
    });

    test('late sessions roll over midnight into the next day', () {
      final p = plan(start: DateTime(2026, 6, 13, 23, 30), distanceKm: 10);
      expect(p.windowHours.first, DateTime(2026, 6, 13, 23));
      expect(p.windowHours.last, DateTime(2026, 6, 14, 0));
    });
  });

  group('formatting', () {
    test('durations read naturally', () {
      expect(formatDuration(0.5), '30 min');
      expect(formatDuration(1.0), '1 h');
      expect(formatDuration(1.5), '1 h 30 min');
    });

    test('distances read naturally', () {
      expect(formatDistance(10), '10 km');
      expect(formatDistance(0.75), '750 m');
      expect(formatDistance(1.5), '1.50 km');
    });
  });

  group('places', () {
    test('round-trip through JSON for local storage', () {
      const place = Place(
        name: 'Kalmar',
        region: 'Kalmar County',
        country: 'Sweden',
        latitude: 56.6616,
        longitude: 16.3616,
      );
      final decoded = Place.decodeList(Place.encodeList([place])).single;
      expect(decoded.name, place.name);
      expect(decoded.latitude, place.latitude);
      expect(decoded.sameSpot(place), isTrue);
    });
  });
}
