import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/screens/quick_session_page.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'fingerprint_test.dart' show FakeHistoryService;
import 'race_test.dart' show ironmanKalmar, kalmar;

class FakeRaceWeather extends FakeHistoryService {
  @override
  Future<List<Place>> searchPlaces(String query) async => const [kalmar];
}

Future<PrefsStore> _freshStore([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return PrefsStore.load();
}

Future<void> _pumpHome(
    WidgetTester tester, PrefsStore store, FakeRaceWeather weather) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: QuickSessionPage(store: store, weather: weather),
  ));
}

void main() {
  testWidgets('add Ironman Kalmar, see its race-day climate, reuse the cache',
      (tester) async {
    final store = await _freshStore();
    final weather = FakeRaceWeather();
    await _pumpHome(tester, store, weather);

    // Optional invitation; Quick Session is still there.
    expect(find.text('Training for a race?'), findsOneWidget);
    expect(find.text('Quick Session'), findsOneWidget);
    await tester.tap(find.text('Training for a race?'));
    await tester.pumpAndSettle();

    // Saving without a place explains what's missing.
    await tester.tap(find.text('Save race'));
    await tester.pump();
    expect(find.text('Pick the race location.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Ironman Kalmar');

    await tester.tap(find.text('Pick the race location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Kalmar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalmar').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Race date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tick swim and bike too -> triathlon quick-fill appears.
    expect(find.text('Ironman'), findsNothing);
    await tester.tap(find.text('Swim'));
    await tester.pump();
    await tester.tap(find.text('Bike'));
    await tester.pump();
    await tester.tap(find.text('Ironman'));
    await tester.pump();
    expect(
        find.textContaining(
            'Swim 07:00–08:15 · Bike 08:15–14:15 · Run 14:15–18:45'),
        findsOneWidget);
    expect(find.textContaining('Total 11 h 45 min'), findsOneWidget);

    await tester.tap(find.text('Save race'));
    await tester.pumpAndSettle();

    // Straight to the race page; the fingerprint is computed and shown.
    expect(find.text('Race-day climate'), findsOneWidget);
    expect(find.textContaining('Kalmar on '), findsOneWidget);
    expect(find.textContaining('07:00–18:45: typically'), findsOneWidget);
    expect(find.textContaining('at the 07:00 start'), findsOneWidget);
    expect(find.text('By leg'), findsOneWidget);
    expect(find.text('Swim 07:00–08:15'), findsOneWidget);
    expect(find.text('Run 14:15–18:45'), findsOneWidget);
    expect(weather.requests, hasLength(10));

    // It's cached on the device.
    final saved = store.races.single;
    expect(saved.name, 'Ironman Kalmar');
    expect(saved.validFingerprint, isNotNull);

    // Back home: the card shows the short summary.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('My races'), findsOneWidget);
    expect(find.text('Ironman Kalmar'), findsOneWidget);
    expect(find.textContaining('Typically'), findsOneWidget);

    // Reopening does not download anything again.
    await tester.tap(find.text('Ironman Kalmar'));
    await tester.pumpAndSettle();
    expect(find.text('Race-day climate'), findsOneWidget);
    expect(weather.requests, hasLength(10));
  });

  testWidgets('damaged saved data never blanks the app', (tester) async {
    final store = await _freshStore({
      'races': ['not', 'a', 'race'],
      'favouritePlaces': 42,
    });
    expect(store.races, isEmpty);
    expect(store.savedPlaces, isEmpty);
    expect(store.trainingWindow.label, '06:00–20:00');
    await _pumpHome(tester, store, FakeRaceWeather());
    expect(find.text('Quick Session'), findsOneWidget);
    expect(find.text('Training for a race?'), findsOneWidget);
  });

  testWidgets('three races is the limit', (tester) async {
    final store = await _freshStore();
    for (final id in ['a', 'b', 'c']) {
      final race = ironmanKalmar();
      expect(
          await store.saveRace(Race(
            id: id,
            name: 'Race $id',
            place: race.place,
            date: race.date,
            startHour: 7,
            startMinute: 0,
            legs: race.legs,
          )),
          isTrue);
    }
    expect(await store.saveRace(ironmanKalmar()), isFalse);

    await _pumpHome(tester, store, FakeRaceWeather());
    expect(find.text('Race a'), findsOneWidget);
    expect(find.text('Race c'), findsOneWidget);
    expect(find.text('Add race'), findsNothing);
    expect(find.text('Up to 3 races – delete one to add another.'),
        findsOneWidget);
  });

  testWidgets('a race can be deleted; the app works without one',
      (tester) async {
    final store = await _freshStore();
    await store.saveRace(ironmanKalmar());
    await _pumpHome(tester, store, FakeRaceWeather());

    await tester.tap(find.text('Ironman Kalmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit race'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete race'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.races, isEmpty);
    expect(find.text('Training for a race?'), findsOneWidget);
    expect(find.text('Quick Session'), findsOneWidget);
  });
}
