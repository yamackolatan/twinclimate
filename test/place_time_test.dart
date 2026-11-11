import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/logic/feedback_logic.dart';
import 'package:twinclimate/logic/place_time.dart';
import 'package:twinclimate/models/comfort.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/screens/quick_session_page.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'app_flow_test.dart' show FakeWeatherService;

/// Time zones: "now" must be judged on the training place's clock.
void main() {
  // 10:00 UTC on 18 Oct 2026.
  final instant = DateTime.utc(2026, 10, 18, 10);

  test('clock at a place follows its UTC offset', () {
    // Kalmar in summer time: UTC+2.
    expect(clockAt(instant, 2 * 3600), DateTime(2026, 10, 18, 12));
    // New York: UTC−4 → 06:00 the same day.
    expect(clockAt(instant, -4 * 3600), DateTime(2026, 10, 18, 6));
    // Far east: UTC+13 → 23:00; UTC+14 → midnight, the next day.
    expect(clockAt(instant, 13 * 3600), DateTime(2026, 10, 18, 23));
    expect(clockAt(instant, 14 * 3600), DateTime(2026, 10, 19, 0));
    // Unknown offset: the moment is used as it is (phone's clock).
    expect(clockAt(instant, null), instant);
  });

  test('a note says how far ahead or behind the place is', () {
    final phone = DateTime.now();
    final own = phone.timeZoneOffset.inSeconds;
    expect(timeDifferenceNote('Vondelpark', own, phone), isNull);
    expect(timeDifferenceNote('Vondelpark', null, phone), isNull);
    expect(
      timeDifferenceNote('Kalmar', own + 3600, phone),
      'Times are local time in Kalmar (1 h ahead of you).',
    );
    expect(
      timeDifferenceNote('Kona', own - 12 * 3600, phone),
      'Times are local time in Kona (12 h behind you).',
    );
    expect(
      timeDifferenceNote('Mumbai', own + 4 * 3600 + 1800, phone),
      'Times are local time in Mumbai (4 h 30 min ahead of you).',
    );
  });

  test('places remember their UTC offset', () {
    const place = Place(
      name: 'Kalmar',
      region: '',
      country: 'Sweden',
      latitude: 56.66,
      longitude: 16.36,
    );
    final decoded = Place.decodeList(
      Place.encodeList([place.withUtcOffset(7200)]),
    ).single;
    expect(decoded.utcOffsetSeconds, 7200);
    expect(decoded.sameSpot(place), isTrue);
    // Older saved places have no offset.
    expect(
      Place.decodeList(Place.encodeList([place])).single.utcOffsetSeconds,
      isNull,
    );
  });

  group('feedback card uses the place\'s clock', () {
    final profile = ComfortProfile(
      feedback: const [],
      manualSettings: const {},
      forgotten: const {},
    );
    // The phone reads 12:00 (in its own zone, whatever that is).
    final phoneNow = DateTime(2026, 10, 18, 12);
    final phoneOffset = phoneNow.timeZoneOffset.inSeconds;

    SessionRecord at(DateTime start, int? offset) => SessionRecord(
      id: '$start/$offset',
      sport: Sport.run,
      placeName: 'Somewhere',
      latitude: 0,
      longitude: 0,
      start: start,
      end: start.add(const Duration(hours: 1)),
      forecastFeelsC: 15,
      suggested: const {BodyPart.torso: 'Tee'},
      utcOffsetSeconds: offset,
    );

    test('a session 3 h behind has not finished yet', () {
      // 09:00–10:00 at a place 3 h behind: it's only 09:00 there now.
      final behind = at(DateTime(2026, 10, 18, 9), phoneOffset - 3 * 3600);
      expect(pickSessionToAsk([behind], profile, phoneNow).ask, isNull);
      // The same session in the phone's own time zone has finished.
      final home = at(DateTime(2026, 10, 18, 9), phoneOffset);
      expect(pickSessionToAsk([home], profile, phoneNow).ask, home);
    });

    test('a session 3 h ahead has finished already', () {
      // 13:00–14:00 at a place 3 h ahead: it's 15:00 there now.
      final ahead = at(DateTime(2026, 10, 18, 13), phoneOffset + 3 * 3600);
      expect(pickSessionToAsk([ahead], profile, phoneNow).ask, ahead);
    });

    test('older records without an offset use the phone clock', () {
      final old = at(DateTime(2026, 10, 18, 9), null);
      expect(pickSessionToAsk([old], profile, phoneNow).ask, old);
    });
  });

  testWidgets('home screen uses the place\'s clock for "Now"', (tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
    // The quick-pick place is 3 hours ahead of the phone.
    final offset = DateTime.now().timeZoneOffset.inSeconds + 3 * 3600;
    final weather = FakeWeatherService()..utcOffsetSeconds = offset;
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(store: store, weather: weather),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Times are local time in Vondelpark (3 h ahead of you).'),
      findsOneWidget,
    );

    final soon = clockAt(
      DateTime.now(),
      offset,
    ).add(const Duration(minutes: 14));
    final start = DateTime(
      soon.year,
      soon.month,
      soon.day,
      soon.hour,
      soon.minute - soon.minute % 15,
    );
    await tester.tap(find.text('Now'));
    await tester.pumpAndSettle();
    expect(
      find.text('${formatDay(start)}, start ${formatTime(start)}'),
      findsOneWidget,
    );
  });
}
